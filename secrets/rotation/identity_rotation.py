#!/usr/bin/env python3
"""Validate and manage identity rotation state without reading private keys."""

from __future__ import annotations

import argparse
import base64
import binascii
import copy
import json
import os
import sys
import tempfile
from collections import Counter
from pathlib import Path
from typing import Any


CATEGORIES = ("home", "identities", "nixos")
TARGET_STATES = ("current", "bridge", "next")
STATE_RANK = {state: rank for rank, state in enumerate(TARGET_STATES)}
ROOT_KEYS = {"schema", "status", "currentIndex", "nextIndex", "targets"}


class RotationError(ValueError):
    """Raised when a manifest or transition violates the rotation contract."""


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise RotationError(f"cannot read {path}: {error}") from error
    if not isinstance(value, dict):
        raise RotationError(f"{path} must contain a JSON object")
    return value


def atomic_write_manifest(path: Path, state: dict[str, Any]) -> None:
    """Replace a manifest without exposing a partially written JSON file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump(state, stream, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)

    try:
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    except OSError:
        # The atomic replacement has completed; some filesystems do not allow
        # directory fsync and should not turn a safe state into an error.
        pass


def discover_targets(repository: Path) -> dict[str, set[str]]:
    """Discover canonical identity targets from repository structure."""
    hosts_dir = repository / "hosts"
    users_dir = repository / "users"

    nixos = {
        path.name
        for path in hosts_dir.iterdir()
        if path.is_dir()
        and (path / "configuration.nix").is_file()
        and path.name != "iso"
    }
    missing_host_keys = sorted(
        host_name
        for host_name in nixos
        if not (hosts_dir / host_name / "ssh_host_ed25519_key.pub").is_file()
    )
    if missing_host_keys:
        raise RotationError(
            f"active hosts lack canonical SSH public keys: {missing_host_keys}"
        )

    home: set[str] = set()
    for host_name in nixos:
        host_users = hosts_dir / host_name / "users"
        if not host_users.is_dir():
            continue
        for path in host_users.iterdir():
            if path.is_file() and path.suffix == ".nix":
                home.add(f"{host_name}-{path.stem}")
            elif path.is_dir() and (path / "home-configuration.nix").is_file():
                home.add(f"{host_name}-{path.name}")

    identities = {
        path.name
        for path in users_dir.iterdir()
        if path.is_dir() and (path / "default.nix").is_file()
    }
    return {"home": home, "identities": identities, "nixos": nixos}


def expected_targets_from_file(path: Path) -> dict[str, set[str]]:
    value = load_manifest(path)
    if set(value) != set(CATEGORIES):
        raise RotationError(f"{path} must contain exactly: {', '.join(CATEGORIES)}")

    expected: dict[str, set[str]] = {}
    for category in CATEGORIES:
        names = value[category]
        if not isinstance(names, list) or not all(
            isinstance(name, str) and name for name in names
        ):
            raise RotationError(f"{path}: {category} must be a list of names")
        expected[category] = set(names)
        if len(expected[category]) != len(names):
            raise RotationError(f"{path}: {category} contains duplicate names")
    return expected


def _require_nonempty_file(path: Path) -> None:
    if not path.is_file() or path.stat().st_size == 0:
        raise RotationError(f"required next artifact is missing or empty: {path}")


def _read_public_artifact(path: Path, kind: str) -> str:
    _require_nonempty_file(path)
    value = path.read_text().strip()
    if kind == "age":
        if (
            len(value) != 62
            or not value.startswith("age1")
            or not value.islower()
            or not value.isalnum()
        ):
            raise RotationError(f"invalid age recipient artifact: {path}")
    elif kind == "ssh":
        fields = value.split()
        if len(fields) < 2 or fields[0] != "ssh-ed25519":
            raise RotationError(f"invalid Ed25519 SSH public artifact: {path}")
        try:
            decoded = base64.b64decode(fields[1], validate=True)
        except (binascii.Error, ValueError) as error:
            raise RotationError(
                f"invalid Ed25519 SSH public artifact: {path}"
            ) from error
        if not decoded.startswith(b"\x00\x00\x00\x0bssh-ed25519"):
            raise RotationError(f"invalid Ed25519 SSH public artifact: {path}")
    else:
        raise AssertionError(f"unknown public artifact kind: {kind}")
    return value


def _require_changed_public_artifact(current: Path, next_path: Path, kind: str) -> None:
    current_value = _read_public_artifact(current, kind)
    next_value = _read_public_artifact(next_path, kind)
    if current_value == next_value:
        raise RotationError(f"next public artifact matches current: {next_path}")


def _require_age_ciphertext(path: Path) -> None:
    _require_nonempty_file(path)
    with path.open("rb") as stream:
        if stream.readline().rstrip(b"\r\n") != b"age-encryption.org/v1":
            raise RotationError(f"invalid age ciphertext artifact: {path}")


def validate_next_artifacts(
    repository: Path, expected_targets: dict[str, set[str]]
) -> None:
    """Require a complete, distinct next-generation artifact set."""
    rotation_next = repository / "secrets/rotation/next"
    for name in ("hex.age", "id_age.age"):
        _require_age_ciphertext(rotation_next / name)
    _require_changed_public_artifact(
        repository / "secrets/id_age.pub", rotation_next / "id_age.pub", "age"
    )

    for host_name in sorted(expected_targets["nixos"]):
        current = repository / f"hosts/{host_name}/ssh_host_ed25519_key.pub"
        _require_changed_public_artifact(
            current, current.with_name(current.name + ".next"), "ssh"
        )

        generated = list(
            (repository / f"secrets/nixos/{host_name}").glob("*-hex-next.age")
        )
        if len(generated) != 1 or generated[0].stat().st_size == 0:
            raise RotationError(
                f"expected one generated hex-next ciphertext for NixOS target {host_name}"
            )
        _require_age_ciphertext(generated[0])

    for identity in sorted(expected_targets["identities"]):
        for name in ("id_age.pub", "id_ed25519.pub"):
            current = repository / f"users/{identity}/{name}"
            _require_changed_public_artifact(
                current,
                current.with_name(current.name + ".next"),
                "age" if name == "id_age.pub" else "ssh",
            )


def create_marker(path: Path, current_index: int, next_index: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        descriptor = os.open(path, flags, 0o644)
    except FileExistsError as error:
        raise RotationError(f"rotation marker already exists: {path}") from error
    with os.fdopen(descriptor, "w") as stream:
        stream.write(f"identity rotation active: {current_index} -> {next_index}\n")
        stream.flush()
        os.fsync(stream.fileno())


def remove_marker(path: Path) -> None:
    path.unlink(missing_ok=True)


def _positive_index(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise RotationError(f"{field} must be a non-negative integer")
    return value


def target_states(state: dict[str, Any]) -> list[str]:
    return [
        target_state
        for category in CATEGORIES
        for target_state in state["targets"][category].values()
    ]


def validate_state(
    state: dict[str, Any],
    *,
    expected_targets: dict[str, set[str]] | None = None,
    derivation_index: int | None = None,
    marker_active: bool | None = None,
) -> None:
    unknown = set(state) - ROOT_KEYS
    missing = ROOT_KEYS - set(state)
    if unknown or missing:
        raise RotationError(
            "manifest fields differ from schema"
            f"; missing={sorted(missing)} unknown={sorted(unknown)}"
        )
    if isinstance(state["schema"], bool) or state["schema"] != 1:
        raise RotationError("schema must be 1")
    if state["status"] not in ("idle", "active"):
        raise RotationError("status must be idle or active")

    current_index = _positive_index(state["currentIndex"], "currentIndex")
    next_index = state["nextIndex"]
    if next_index is not None:
        next_index = _positive_index(next_index, "nextIndex")
        if next_index == current_index:
            raise RotationError("currentIndex and nextIndex must differ")

    targets = state["targets"]
    if not isinstance(targets, dict) or set(targets) != set(CATEGORIES):
        raise RotationError(f"targets must contain exactly: {', '.join(CATEGORIES)}")

    for category in CATEGORIES:
        category_targets = targets[category]
        if not isinstance(category_targets, dict):
            raise RotationError(f"targets.{category} must be an object")
        for name, value in category_targets.items():
            if not isinstance(name, str) or not name:
                raise RotationError(f"targets.{category} contains an invalid name")
            if value not in TARGET_STATES:
                raise RotationError(
                    f"targets.{category}.{name} must be current, bridge, or next"
                )

        if expected_targets is not None:
            actual_names = set(category_targets)
            expected_names = expected_targets[category]
            if actual_names != expected_names:
                raise RotationError(
                    f"targets.{category} differs from repository"
                    f"; missing={sorted(expected_names - actual_names)}"
                    f" stale={sorted(actual_names - expected_names)}"
                )

    if derivation_index is not None and current_index != derivation_index:
        raise RotationError(
            f"currentIndex {current_index} does not match derivationIndex "
            f"{derivation_index}"
        )

    all_states = target_states(state)
    if not all_states:
        raise RotationError("manifest must contain at least one target")
    if state["status"] == "idle":
        if next_index is not None:
            raise RotationError("idle state must not have nextIndex")
        if any(value != "current" for value in all_states):
            raise RotationError("idle state requires every target to be current")
    elif next_index is None:
        raise RotationError("active state requires nextIndex")

    if marker_active is not None and marker_active != (state["status"] == "active"):
        raise RotationError("ACTIVE marker and manifest status disagree")


def _target_changes(
    before: dict[str, Any], after: dict[str, Any]
) -> list[tuple[str, str, str, str]]:
    changes: list[tuple[str, str, str, str]] = []
    for category in CATEGORIES:
        before_targets = before["targets"][category]
        after_targets = after["targets"][category]
        if set(before_targets) != set(after_targets):
            raise RotationError(f"transition changes targets.{category} membership")
        for name, old_state in before_targets.items():
            new_state = after_targets[name]
            if old_state != new_state:
                changes.append((category, name, old_state, new_state))
    return changes


def validate_transition(before: dict[str, Any], after: dict[str, Any]) -> None:
    """Validate one atomic manifest transition."""
    validate_state(before)
    validate_state(after)
    if before["schema"] != after["schema"]:
        raise RotationError("transition changes schema")

    changes = _target_changes(before, after)
    before_status = before["status"]
    after_status = after["status"]

    if before_status == "idle" and after_status == "active":
        if before["currentIndex"] != after["currentIndex"]:
            raise RotationError("prepare changes currentIndex")
        if changes:
            raise RotationError("prepare must leave every target current")
        return

    if before_status == "active" and after_status == "active":
        if (
            before["currentIndex"] != after["currentIndex"]
            or before["nextIndex"] != after["nextIndex"]
        ):
            raise RotationError("active transition changes derivation indexes")
        if len(changes) != 1:
            raise RotationError("active transition must change exactly one target")
        _, _, old_state, new_state = changes[0]
        if abs(STATE_RANK[old_state] - STATE_RANK[new_state]) != 1:
            raise RotationError("target transition must move through bridge")
        return

    if before_status == "active" and after_status == "idle":
        if target_states(after) != ["current"] * len(target_states(after)):
            raise RotationError("idle destination must normalize targets to current")
        if before["nextIndex"] is None:
            raise RotationError("active source lacks nextIndex")

        if all(value == "current" for value in target_states(before)):
            if after["currentIndex"] != before["currentIndex"]:
                raise RotationError("rollback changes currentIndex")
            return

        if all(value == "next" for value in target_states(before)):
            if after["currentIndex"] != before["nextIndex"]:
                raise RotationError("finalize does not promote nextIndex")
            return

        raise RotationError("cannot leave active state with partially migrated targets")

    raise RotationError(
        f"unsupported status transition {before_status}->{after_status}"
    )


def managed_context(
    manifest: Path,
    repository: Path,
    derivation_index: int,
    marker: Path,
    *,
    marker_active: bool | None = None,
) -> tuple[dict[str, Any], dict[str, set[str]]]:
    state = load_manifest(manifest)
    expected = discover_targets(repository)
    validate_state(
        state,
        expected_targets=expected,
        derivation_index=derivation_index,
        marker_active=marker.exists() if marker_active is None else marker_active,
    )
    return state, expected


def command_validate(args: argparse.Namespace) -> None:
    state = load_manifest(args.manifest)
    if args.repository is not None:
        expected = discover_targets(args.repository)
        marker = args.marker or args.repository / "secrets/rotation/ACTIVE"
    else:
        expected = expected_targets_from_file(args.expected_targets)
        marker = args.marker

    if marker is None:
        raise RotationError("--marker is required with --expected-targets")

    validate_state(
        state,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=marker.exists(),
    )
    print("identity rotation state valid")


def command_transition(args: argparse.Namespace) -> None:
    validate_transition(load_manifest(args.before), load_manifest(args.after))
    print("identity rotation transition valid")


def command_status(args: argparse.Namespace) -> None:
    state, _ = managed_context(
        args.manifest,
        args.repository,
        args.derivation_index,
        args.marker,
    )
    counts = Counter(target_states(state))
    print(
        "identity rotation"
        f" status={state['status']}"
        f" currentIndex={state['currentIndex']}"
        f" nextIndex={state['nextIndex']}"
        f" current={counts['current']}"
        f" bridge={counts['bridge']}"
        f" next={counts['next']}"
    )


def command_prepare(args: argparse.Namespace) -> None:
    before, expected = managed_context(
        args.manifest,
        args.repository,
        args.derivation_index,
        args.marker,
    )
    if before["status"] != "idle":
        raise RotationError("prepare requires idle state")
    if args.next_index == before["currentIndex"]:
        raise RotationError("next index must differ from currentIndex")

    validate_next_artifacts(args.repository, expected)
    after = copy.deepcopy(before)
    after["status"] = "active"
    after["nextIndex"] = args.next_index
    validate_transition(before, after)
    validate_state(
        after,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=True,
    )

    create_marker(args.marker, before["currentIndex"], args.next_index)
    try:
        atomic_write_manifest(args.manifest, after)
    except Exception:
        remove_marker(args.marker)
        raise
    print(f"identity rotation prepared: {before['currentIndex']} -> {args.next_index}")


def command_move(args: argparse.Namespace) -> None:
    before, expected = managed_context(
        args.manifest,
        args.repository,
        args.derivation_index,
        args.marker,
    )
    if before["status"] != "active":
        raise RotationError("target moves require active state")
    if args.name not in before["targets"][args.category]:
        raise RotationError(
            f"unknown identity rotation target {args.category}.{args.name}"
        )

    after = copy.deepcopy(before)
    after["targets"][args.category][args.name] = args.target_state
    validate_transition(before, after)
    validate_state(
        after,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=True,
    )
    atomic_write_manifest(args.manifest, after)
    print(
        f"identity rotation target: {args.category}.{args.name} -> {args.target_state}"
    )


def command_cancel(args: argparse.Namespace) -> None:
    state = load_manifest(args.manifest)
    expected = discover_targets(args.repository)

    # A crash after marker creation but before the active manifest replacement
    # leaves an idle ledger with a marker. Cancellation safely resumes cleanup.
    if state["status"] == "idle" and args.marker.exists():
        validate_state(
            state,
            expected_targets=expected,
            derivation_index=args.derivation_index,
            marker_active=False,
        )
        remove_marker(args.marker)
        print("identity rotation prepare marker removed")
        return

    validate_state(
        state,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=args.marker.exists(),
    )
    if state["status"] != "active":
        raise RotationError("cancel requires active state")

    after = copy.deepcopy(state)
    after["status"] = "idle"
    after["nextIndex"] = None
    validate_transition(state, after)
    validate_state(
        after,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=False,
    )
    atomic_write_manifest(args.manifest, after)
    remove_marker(args.marker)
    print("identity rotation cancelled")


def add_managed_arguments(command: argparse.ArgumentParser) -> None:
    command.add_argument("manifest", type=Path)
    command.add_argument("--repository", type=Path, required=True)
    command.add_argument("--derivation-index", type=int, required=True)
    command.add_argument("--marker", type=Path, required=True)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)

    validate = commands.add_parser("validate", help="validate a state manifest")
    validate.add_argument("manifest", type=Path)
    source = validate.add_mutually_exclusive_group(required=True)
    source.add_argument("--repository", type=Path)
    source.add_argument("--expected-targets", type=Path)
    validate.add_argument("--derivation-index", type=int, required=True)
    validate.add_argument("--marker", type=Path)
    validate.set_defaults(run=command_validate)

    transition = commands.add_parser("transition", help="validate one transition")
    transition.add_argument("before", type=Path)
    transition.add_argument("after", type=Path)
    transition.set_defaults(run=command_transition)

    status = commands.add_parser("status", help="show validated managed state")
    add_managed_arguments(status)
    status.set_defaults(run=command_status)

    prepare = commands.add_parser(
        "prepare", help="enter active state after validating next artifacts"
    )
    add_managed_arguments(prepare)
    prepare.add_argument("next_index", type=int)
    prepare.set_defaults(run=command_prepare)

    move = commands.add_parser("move", help="move one target by one adjacent state")
    add_managed_arguments(move)
    move.add_argument("category", choices=CATEGORIES)
    move.add_argument("name")
    move.add_argument("target_state", choices=TARGET_STATES)
    move.set_defaults(run=command_move)

    cancel = commands.add_parser(
        "cancel", help="leave active state after every target returns to current"
    )
    add_managed_arguments(cancel)
    cancel.set_defaults(run=command_cancel)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.run(args)
    except RotationError as error:
        print(f"identity rotation state invalid: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
