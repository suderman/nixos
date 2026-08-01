#!/usr/bin/env python3
"""Finalize a fleet identity rotation through a recoverable transaction."""

from __future__ import annotations

import argparse
import copy
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

from identity_artifacts import (  # noqa: E402
    ArtifactError,
    build_rekey_package,
    copy_tracked_repository,
    evaluate_hosts,
    run,
    sha256,
)
from identity_rotation import (  # noqa: E402
    RotationError,
    atomic_write_manifest,
    discover_targets,
    load_manifest,
    next_hosts,
    prepared_hosts,
    target_states,
    validate_artifact_manifest,
    validate_state,
    validate_transition,
)


class FinalizationError(RuntimeError):
    """Raised when identity finalization cannot complete safely."""


def relative_to_repository(repository: Path, path: Path) -> Path:
    try:
        return path.resolve().relative_to(repository)
    except ValueError as error:
        raise FinalizationError(f"path is outside the repository: {path}") from error


def atomic_copy(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{target.name}.rotation.", dir=target.parent
    )
    os.close(descriptor)
    temporary = Path(temporary_name)
    try:
        shutil.copy2(source, temporary)
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)


def remove_empty_parents(path: Path, stop: Path) -> None:
    parent = path.parent
    while parent != stop and parent.is_dir() and not any(parent.iterdir()):
        parent.rmdir()
        parent = parent.parent


def require_clean_repository(repository: Path) -> None:
    status = run(
        ["git", "status", "--porcelain", "--untracked-files=all"],
        cwd=repository,
        capture=True,
    )
    if status:
        raise FinalizationError("identity finalization requires a clean worktree")


def tracked_paths(repository: Path) -> set[Path]:
    output = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=repository,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    return {Path(os.fsdecode(value)) for value in output.split(b"\0") if value}


def verify_identity(identity: Path, recipient: Path) -> None:
    if not identity.is_file():
        raise FinalizationError(f"required runtime identity is missing: {identity}")
    actual = run(["derive", "public"], input_text=identity.read_text(), capture=True)
    expected = recipient.read_text().strip()
    if actual != expected:
        raise FinalizationError(f"runtime identity does not match {recipient}")


def ensure_next_runtime_identity(encrypted: Path, identity: Path) -> None:
    if identity.is_file():
        return
    identity.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{identity.name}.", dir=identity.parent
    )
    os.close(descriptor)
    temporary = Path(temporary_name)
    try:
        run(
            [
                "age",
                "--decrypt",
                "--output",
                str(temporary),
                str(encrypted),
            ]
        )
        temporary.chmod(0o600)
        os.replace(temporary, identity)
    finally:
        temporary.unlink(missing_ok=True)


def finalized_state(state: dict[str, Any]) -> dict[str, Any]:
    if state["status"] != "active" or state["nextIndex"] is None:
        raise FinalizationError("finalization requires active rotation state")
    if any(value != "next" for value in target_states(state)):
        raise FinalizationError("finalization requires every target at next")
    if prepared_hosts(state) != set(state["targets"]["nixos"]):
        raise FinalizationError("finalization requires every NixOS host prepared")
    if next_hosts(state) != set(state["targets"]["nixos"]):
        raise FinalizationError(
            "finalization requires every NixOS host attested at next"
        )

    result = copy.deepcopy(state)
    result["status"] = "idle"
    result["currentIndex"] = state["nextIndex"]
    result["nextIndex"] = None
    result["preparedHosts"] = []
    result["nextHosts"] = []
    for category in result["targets"].values():
        for name in category:
            category[name] = "current"
    validate_transition(state, result)
    return result


def replace_derivation_index(path: Path, current_index: int, next_index: int) -> None:
    value = path.read_text()
    pattern = rf"(derivationIndex\s*=\s*){current_index}(\s*;)"
    value, replacements = re.subn(pattern, rf"\g<1>{next_index}\g<2>", value)
    if replacements != 1:
        raise FinalizationError("could not replace the declared derivation index")
    path.write_text(value)


def decrypt_secret(path: Path, identities: list[Path]) -> bytes:
    arguments = ["age", "--decrypt"]
    for identity in identities:
        arguments.extend(["--identity", str(identity)])
    arguments.append(str(path))
    return subprocess.run(arguments, check=True, stdout=subprocess.PIPE).stdout


def encrypt_secret(value: bytes, recipient: Path, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{output.name}.rekey.", dir=output.parent
    )
    os.close(descriptor)
    temporary = Path(temporary_name)
    try:
        subprocess.run(
            [
                "age",
                "--encrypt",
                "--recipients-file",
                str(recipient),
                "--output",
                str(temporary),
            ],
            input=value,
            check=True,
        )
        if output.exists():
            temporary.chmod(output.stat().st_mode & 0o777)
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)


def reencrypt_sources(
    production: Path,
    temporary: Path,
    source_hashes: dict[str, str],
    next_recipient: Path,
    identities: list[Path],
) -> None:
    for relative_value in sorted(source_hashes):
        relative = Path(relative_value)
        source = production / relative
        output = temporary / relative
        if relative == Path("secrets/hex.age"):
            atomic_copy(temporary / "secrets/rotation/next/hex.age", output)
            continue

        plaintext = decrypt_secret(source, identities)
        encrypt_secret(plaintext, next_recipient, output)
        if decrypt_secret(output, [identities[-1]]) != plaintext:
            raise FinalizationError(f"failed to verify re-encrypted source: {relative}")


def promote_public_artifacts(repository: Path, expected: dict[str, set[str]]) -> None:
    atomic_copy(
        repository / "secrets/rotation/next/id_age.pub",
        repository / "secrets/id_age.pub",
    )
    for host in sorted(expected["nixos"]):
        current = repository / f"hosts/{host}/ssh_host_ed25519_key.pub"
        atomic_copy(current.with_name(current.name + ".next"), current)
    for identity in sorted(expected["identities"]):
        for name in ("id_age.pub", "id_ed25519.pub"):
            current = repository / "users" / identity / name
            atomic_copy(current.with_name(current.name + ".next"), current)


def configure_next_only_master(repository: Path, next_identity: Path) -> str:
    path = repository / "secrets/default.nix"
    original = path.read_text()
    current = """masterIdentities =
          [/tmp/id_age /tmp/id_age_]
          ++ lib.optional rotationActive /tmp/id_age_next;"""
    replacement = (
        "masterIdentities = ["
        f"(builtins.toPath {json.dumps(str(next_identity.resolve()))})"
        "];"
    )
    if original.count(current) != 1:
        raise FinalizationError("could not isolate the final master identity")
    path.write_text(original.replace(current, replacement))
    return original


def generate_final_ciphertext(
    repository: Path, system: str, next_identity: Path
) -> None:
    module = repository / "secrets/default.nix"
    original = configure_next_only_master(repository, next_identity)
    try:
        rekey = build_rekey_package(repository, system)
        environment = os.environ.copy()
        environment["AGENIX_REKEY_ADD_TO_GIT"] = "false"
        run([str(rekey), "--force"], cwd=repository, environment=environment)
    finally:
        module.write_text(original)


def remove_prepared_artifacts(
    repository: Path, artifact_manifest: dict[str, Any]
) -> None:
    for relative_value in artifact_manifest["artifacts"]:
        path = repository / relative_value
        path.unlink(missing_ok=True)
        remove_empty_parents(path, repository)
    manifest = repository / "secrets/rotation/next/artifacts.json"
    manifest.unlink(missing_ok=True)
    remove_empty_parents(manifest, repository)


def prepare_final_tree(
    production: Path,
    destination: Path,
    state_path: Path,
    marker: Path,
    current_index: int,
    system: str,
    identities: list[Path],
    next_identity: Path,
) -> tuple[dict[str, Any], dict[str, set[str]]]:
    copy_tracked_repository(production, destination)
    relative_state = relative_to_repository(production, state_path)
    relative_marker = relative_to_repository(production, marker)
    state = load_manifest(destination / relative_state)
    expected = discover_targets(destination)
    validate_state(
        state,
        expected_targets=expected,
        derivation_index=current_index,
        marker_active=True,
    )
    validate_artifact_manifest(destination, expected, state["nextIndex"])
    result_state = finalized_state(state)
    artifact_manifest = load_manifest(
        destination / "secrets/rotation/next/artifacts.json"
    )

    promote_public_artifacts(destination, expected)
    reencrypt_sources(
        production,
        destination,
        artifact_manifest["sourceSecrets"],
        destination / "secrets/rotation/next/id_age.pub",
        identities,
    )
    replace_derivation_index(
        destination / "flake.nix",
        state["currentIndex"],
        result_state["currentIndex"],
    )
    atomic_write_manifest(destination / relative_state, result_state)
    (destination / relative_marker).unlink()
    remove_prepared_artifacts(destination, artifact_manifest)

    generate_final_ciphertext(destination, system, next_identity)
    validate_state(
        result_state,
        expected_targets=expected,
        derivation_index=result_state["currentIndex"],
        marker_active=False,
    )
    evaluate_hosts(destination, expected["nixos"])
    return artifact_manifest, expected


def final_changes(
    production: Path,
    final_tree: Path,
    artifact_manifest: dict[str, Any],
    expected: dict[str, set[str]],
) -> dict[Path, Path | None]:
    candidates = {
        Path("flake.nix"),
        Path("secrets/rotation/state.json"),
        Path("secrets/rotation/ACTIVE"),
        Path("secrets/rotation/next/artifacts.json"),
        *map(Path, artifact_manifest["sourceSecrets"]),
        *map(Path, artifact_manifest["artifacts"]),
    }
    candidates.add(Path("secrets/id_age.pub"))
    candidates.update(
        Path(f"hosts/{host}/ssh_host_ed25519_key.pub") for host in expected["nixos"]
    )
    for identity in expected["identities"]:
        candidates.add(Path(f"users/{identity}/id_age.pub"))
        candidates.add(Path(f"users/{identity}/id_ed25519.pub"))

    production_tracked = tracked_paths(production)
    candidates.update(
        path
        for path in production_tracked
        if path.parts[:2] in (("secrets", "nixos"), ("secrets", "home"))
    )
    candidates.update(
        path.relative_to(final_tree)
        for category in ("nixos", "home")
        for path in (final_tree / "secrets" / category).rglob("*.age")
    )

    changes: dict[Path, Path | None] = {}
    for relative in sorted(candidates, key=lambda value: value.as_posix()):
        before = production / relative
        after = final_tree / relative
        if after.is_file():
            if not before.is_file() or sha256(before) != sha256(after):
                changes[relative] = after
        elif before.exists():
            changes[relative] = None

    private_master = production / "secrets/id_age.age"
    if not private_master.is_file():
        raise FinalizationError(
            f"current encrypted master is missing: {private_master}"
        )
    changes[Path("secrets/id_age.age")] = (
        production / "secrets/rotation/next/id_age.age"
    )
    return changes


def write_transaction(
    repository: Path,
    changes: dict[Path, Path | None],
    journal: Path,
    backup: Path,
) -> dict[str, Any]:
    if journal.exists() or backup.exists():
        raise FinalizationError("recover the existing finalization transaction first")
    value = {
        "schema": 1,
        "status": "backing-up",
        "backup": str(backup),
        "changes": {
            relative.as_posix(): {
                "before": sha256(repository / relative)
                if (repository / relative).is_file()
                else None,
                "after": sha256(source) if source is not None else None,
            }
            for relative, source in changes.items()
        },
    }
    atomic_write_manifest(journal, value)
    backup.mkdir(parents=True)
    for relative, hashes in value["changes"].items():
        if hashes["before"] is not None:
            atomic_copy(repository / relative, backup / relative)
    value["status"] = "installing"
    atomic_write_manifest(journal, value)
    return value


def verify_change_state(
    repository: Path, changes: dict[str, dict[str, str | None]], field: str
) -> None:
    for relative, hashes in changes.items():
        expected = hashes[field]
        path = repository / relative
        if expected is None:
            if path.exists():
                raise FinalizationError(
                    f"unexpected path after finalization: {relative}"
                )
        elif not path.is_file() or sha256(path) != expected:
            raise FinalizationError(f"finalization {field} hash mismatch: {relative}")


def validate_transaction(
    transaction: dict[str, Any], backup: Path
) -> tuple[str, dict[str, dict[str, str | None]]]:
    if set(transaction) != {"schema", "status", "backup", "changes"}:
        raise FinalizationError("invalid finalization transaction schema")
    if transaction["schema"] != 1 or transaction["backup"] != str(backup):
        raise FinalizationError("invalid finalization transaction journal")
    status = transaction["status"]
    if status not in ("backing-up", "installing", "committed"):
        raise FinalizationError(f"unknown finalization transaction status: {status}")
    changes = transaction["changes"]
    if not isinstance(changes, dict) or not changes:
        raise FinalizationError("invalid finalization change ledger")
    for relative_value, hashes in changes.items():
        relative = Path(relative_value)
        if (
            not relative_value
            or relative.is_absolute()
            or ".." in relative.parts
            or not isinstance(hashes, dict)
            or set(hashes) != {"before", "after"}
        ):
            raise FinalizationError("invalid finalization change entry")
        for value in hashes.values():
            if value is not None and (
                not isinstance(value, str)
                or len(value) != 64
                or any(character not in "0123456789abcdef" for character in value)
            ):
                raise FinalizationError(f"invalid finalization change hash: {relative}")
    return status, changes


def apply_changes(
    repository: Path,
    changes: dict[Path, Path | None],
    transaction: dict[str, Any],
    journal: Path,
) -> None:
    fail_after = int(os.environ.get("IDENTITY_ROTATION_FINALIZE_FAIL_AFTER", "0"))
    ordered = sorted(
        changes,
        key=lambda path: (
            path == Path("secrets/rotation/ACTIVE"),
            path == Path("secrets/rotation/state.json"),
            path.as_posix(),
        ),
    )
    for count, relative in enumerate(ordered, start=1):
        source = changes[relative]
        target = repository / relative
        if source is None:
            target.unlink(missing_ok=True)
            remove_empty_parents(target, repository)
        else:
            atomic_copy(source, target)
        if fail_after == count:
            raise FinalizationError(
                f"injected finalization failure after change {count}"
            )

    verify_change_state(repository, transaction["changes"], "after")
    transaction["status"] = "committed"
    atomic_write_manifest(journal, transaction)


def promote_runtime_identity(
    repository: Path, current: Path, previous: Path, next_identity: Path
) -> None:
    recipient = repository / "secrets/id_age.pub"
    if next_identity.is_file():
        verify_identity(next_identity, recipient)
        atomic_copy(next_identity, current)
        current.chmod(0o600)
    verify_identity(current, recipient)
    previous.unlink(missing_ok=True)
    next_identity.unlink(missing_ok=True)


def cleanup_transaction(journal: Path, backup: Path) -> None:
    shutil.rmtree(backup, ignore_errors=True)
    journal.unlink(missing_ok=True)


def recover_transaction(
    repository: Path,
    journal: Path,
    backup: Path,
    runtime_current: Path,
    runtime_previous: Path,
    runtime_next: Path,
) -> None:
    if not journal.is_file():
        raise FinalizationError(f"no finalization journal found: {journal}")
    transaction = load_manifest(journal)
    status, changes = validate_transaction(transaction, backup)

    if status == "backing-up":
        cleanup_transaction(journal, backup)
        print("identity rotation finalization backup removed")
        return
    if status == "committed":
        verify_change_state(repository, changes, "after")
        promote_runtime_identity(
            repository, runtime_current, runtime_previous, runtime_next
        )
        cleanup_transaction(journal, backup)
        print("identity rotation finalization completed")
        return
    for relative, hashes in changes.items():
        path = repository / relative
        if path.exists():
            actual = sha256(path)
            if actual not in (hashes["before"], hashes["after"]):
                raise FinalizationError(
                    f"refusing to overwrite changed path: {relative}"
                )
        before = hashes["before"]
        if before is None:
            path.unlink(missing_ok=True)
            remove_empty_parents(path, repository)
        else:
            source = backup / relative
            if not source.is_file() or sha256(source) != before:
                raise FinalizationError(f"finalization backup is invalid: {relative}")
            atomic_copy(source, path)
    verify_change_state(repository, changes, "before")
    cleanup_transaction(journal, backup)
    print("identity rotation finalization rolled back")


def command_finalize(args: argparse.Namespace) -> None:
    repository = args.repository.resolve()
    manifest = (repository / args.manifest).resolve()
    marker = (repository / args.marker).resolve()
    journal = (repository / args.journal).resolve()
    backup = (repository / args.backup).resolve()
    require_clean_repository(repository)

    state = load_manifest(manifest)
    expected = discover_targets(repository)
    validate_state(
        state,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=marker.exists(),
    )
    validate_artifact_manifest(repository, expected, state["nextIndex"])
    finalized_state(state)

    next_master = repository / "secrets/rotation/next/id_age.age"
    next_recipient = repository / "secrets/rotation/next/id_age.pub"
    ensure_next_runtime_identity(next_master, args.runtime_next)
    verify_identity(args.runtime_next, next_recipient)
    identities = [
        path
        for path in (args.runtime_current, args.runtime_previous, args.runtime_next)
        if path.is_file()
    ]

    with tempfile.TemporaryDirectory(prefix="identity-rotation-finalize.") as value:
        work = Path(value)
        final_tree = work / "repository"
        artifact_manifest, expected = prepare_final_tree(
            repository,
            final_tree,
            manifest,
            marker,
            args.derivation_index,
            args.system,
            identities,
            args.runtime_next,
        )
        changes = final_changes(repository, final_tree, artifact_manifest, expected)
        transaction = write_transaction(repository, changes, journal, backup)
        try:
            apply_changes(repository, changes, transaction, journal)
            promote_runtime_identity(
                repository,
                args.runtime_current,
                args.runtime_previous,
                args.runtime_next,
            )
            args.paths_output.write_text(
                "\n".join(
                    sorted(
                        path.as_posix()
                        for path in changes
                        if path != Path("secrets/id_age.age")
                    )
                )
                + "\n"
            )
            cleanup_transaction(journal, backup)
        except Exception:
            if journal.exists():
                recover_transaction(
                    repository,
                    journal,
                    backup,
                    args.runtime_current,
                    args.runtime_previous,
                    args.runtime_next,
                )
            raise
    print("identity rotation cryptographic finalization completed")


def command_recover(args: argparse.Namespace) -> None:
    repository = args.repository.resolve()
    recover_transaction(
        repository,
        (repository / args.journal).resolve(),
        (repository / args.backup).resolve(),
        args.runtime_current,
        args.runtime_previous,
        args.runtime_next,
    )


def add_runtime_arguments(command: argparse.ArgumentParser) -> None:
    command.add_argument("--runtime-current", type=Path, required=True)
    command.add_argument("--runtime-previous", type=Path, required=True)
    command.add_argument("--runtime-next", type=Path, required=True)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)

    finalize = commands.add_parser("finalize")
    finalize.add_argument("--repository", type=Path, required=True)
    finalize.add_argument("--manifest", type=Path, required=True)
    finalize.add_argument("--marker", type=Path, required=True)
    finalize.add_argument("--journal", type=Path, required=True)
    finalize.add_argument("--backup", type=Path, required=True)
    finalize.add_argument("--derivation-index", type=int, required=True)
    finalize.add_argument("--system", required=True)
    finalize.add_argument("--paths-output", type=Path, required=True)
    add_runtime_arguments(finalize)
    finalize.set_defaults(run=command_finalize)

    recover = commands.add_parser("recover")
    recover.add_argument("--repository", type=Path, required=True)
    recover.add_argument("--journal", type=Path, required=True)
    recover.add_argument("--backup", type=Path, required=True)
    add_runtime_arguments(recover)
    recover.set_defaults(run=command_recover)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.run(args)
    except (
        ArtifactError,
        FinalizationError,
        RotationError,
        OSError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"identity rotation finalization error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
