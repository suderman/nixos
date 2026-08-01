#!/usr/bin/env python3
"""Validate identity rotation state without reading identity material."""

from __future__ import annotations

import argparse
import json
import sys
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
