#!/usr/bin/env python3
"""Prepare and recover fleet-wide identity rotation artifacts."""

from __future__ import annotations

import argparse
import copy
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

from identity_rotation import (  # noqa: E402
    RotationError,
    atomic_write_manifest,
    discover_targets,
    load_manifest,
    validate_artifact_manifest,
    validate_state,
)


class ArtifactError(RuntimeError):
    """Raised when artifact preparation cannot complete safely."""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_private(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value)
    path.chmod(0o600)


def run(
    arguments: list[str],
    *,
    cwd: Path | None = None,
    input_text: str | None = None,
    capture: bool = False,
    environment: dict[str, str] | None = None,
) -> str:
    result = subprocess.run(
        arguments,
        cwd=cwd,
        input=input_text,
        text=True,
        check=True,
        stdout=subprocess.PIPE if capture else None,
        env=environment,
    )
    return result.stdout.strip() if capture else ""


def require_clean_repository(repository: Path) -> None:
    status = run(
        ["git", "status", "--porcelain", "--untracked-files=all"],
        cwd=repository,
        capture=True,
    )
    if status:
        raise ArtifactError("artifact preparation requires a clean worktree")


def copy_tracked_repository(repository: Path, destination: Path) -> None:
    archive = subprocess.run(
        ["git", "archive", "--format=tar", "HEAD"],
        cwd=repository,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    destination.mkdir(parents=True)
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as source:
        source.extractall(destination, filter="data")


def derive(value: str, *arguments: str) -> str:
    return run(["derive", *arguments], input_text=f"{value}\n", capture=True)


def write_next_identities(
    repository: Path,
    root: str,
    next_index: int,
    expected: dict[str, set[str]],
    *,
    test_mode: bool,
) -> Path:
    rotation_next = repository / "secrets/rotation/next"
    rotation_next.mkdir(parents=True, exist_ok=True)

    master_identity = rotation_next / ".id_age"
    write_private(master_identity, f"{derive(root, 'age')}\n")
    master_public = derive(master_identity.read_text(), "public")
    (rotation_next / "id_age.pub").write_text(f"{master_public}\n")

    if test_mode:
        run(
            [
                "age",
                "--encrypt",
                "--recipient",
                master_public,
                "--output",
                str(rotation_next / "id_age.age"),
                str(master_identity),
            ]
        )
    else:
        run(
            [
                "age",
                "--encrypt",
                "--passphrase",
                "--output",
                str(rotation_next / "id_age.age"),
                str(master_identity),
            ]
        )

    root_plaintext = rotation_next / ".hex"
    write_private(root_plaintext, f"{root}\n")
    run(
        [
            "age",
            "--encrypt",
            "--recipient",
            master_public,
            "--output",
            str(rotation_next / "hex.age"),
            str(root_plaintext),
        ]
    )
    recovered = run(
        [
            "age",
            "--decrypt",
            "--identity",
            str(master_identity),
            str(rotation_next / "hex.age"),
        ],
        capture=True,
    )
    if recovered != root:
        raise ArtifactError("failed to verify the encrypted next root")

    derivation_path = f"bip85-hex32-index{next_index}"
    for host in sorted(expected["nixos"]):
        child = derive(root, "hex", host)
        private = derive(child, "ssh")
        public = derive(private, "public", f"{host}@{derivation_path}")
        path = repository / f"hosts/{host}/ssh_host_ed25519_key.pub.next"
        path.write_text(f"{public}\n")

    for identity in sorted(expected["identities"]):
        child = derive(root, "hex", identity)
        ssh_private = derive(child, "ssh")
        age_private = derive(child, "age")
        user_dir = repository / "users" / identity
        (user_dir / "id_ed25519.pub.next").write_text(
            f"{derive(ssh_private, 'public', f'{identity}@{derivation_path}')}\n"
        )
        (user_dir / "id_age.pub.next").write_text(f"{derive(age_private, 'public')}\n")

    root_plaintext.unlink()
    return master_identity


def active_state(
    state: dict[str, Any], next_index: int, target_state: str
) -> dict[str, Any]:
    result = copy.deepcopy(state)
    result["status"] = "active"
    result["nextIndex"] = next_index
    result["preparedHosts"] = []
    result["nextHosts"] = []
    for category in result["targets"].values():
        for name in category:
            category[name] = target_state
    return result


def build_rekey_package(repository: Path, system: str) -> Path:
    output = run(
        [
            "nix",
            "build",
            "--no-link",
            "--print-out-paths",
            f"path:{repository}#agenix-rekey.{system}.rekey",
        ],
        cwd=repository,
        capture=True,
    )
    paths = output.splitlines()
    if len(paths) != 1:
        raise ArtifactError("could not identify the agenix-rekey package output")
    return Path(paths[0]) / "bin/agenix-rekey"


def snapshot_generated(repository: Path, destination: Path) -> None:
    for category in ("nixos", "home"):
        source = repository / "secrets" / category
        if source.is_dir():
            shutil.copytree(source, destination / "secrets" / category)


def generate_slot(
    repository: Path,
    state_path: Path,
    marker: Path,
    state: dict[str, Any],
    destination: Path,
    system: str,
    *,
    dummy: bool,
) -> None:
    atomic_write_manifest(state_path, state)
    marker.write_text("identity rotation artifact preparation\n")
    rekey = build_rekey_package(repository, system)
    arguments = [str(rekey), "--force"]
    if dummy:
        arguments.append("--dummy")
    environment = os.environ.copy()
    environment["AGENIX_REKEY_ADD_TO_GIT"] = "false"
    run(arguments, cwd=repository, environment=environment)
    snapshot_generated(repository, destination)


def merge_generated(slots: list[Path], destination: Path) -> None:
    for slot in slots:
        source = slot / "secrets"
        if not source.is_dir():
            continue
        for path in source.rglob("*.age"):
            relative = path.relative_to(slot)
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() and target.read_bytes() != path.read_bytes():
                raise ArtifactError(f"generated artifact collision: {relative}")
            if not target.exists():
                shutil.copy2(path, target)


def source_secret_hashes(repository: Path) -> dict[str, str]:
    output = subprocess.run(
        ["git", "ls-files", "-z", "--", "*.age"],
        cwd=repository,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    result: dict[str, str] = {}
    for raw_path in output.split(b"\0"):
        if not raw_path:
            continue
        relative = Path(os.fsdecode(raw_path))
        value = relative.as_posix()
        if value.startswith(
            ("secrets/nixos/", "secrets/home/", "secrets/rotation/next/")
        ):
            continue
        result[value] = sha256(repository / relative)
    return dict(sorted(result.items()))


def copy_candidate_artifacts(
    temporary_repository: Path,
    production_repository: Path,
    generated_union: Path,
    staging: Path,
) -> list[Path]:
    candidates: list[Path] = [
        Path("secrets/rotation/next/hex.age"),
        Path("secrets/rotation/next/id_age.age"),
        Path("secrets/rotation/next/id_age.pub"),
    ]
    candidates.extend(
        path.relative_to(temporary_repository)
        for path in sorted(
            temporary_repository.glob("hosts/*/ssh_host_ed25519_key.pub.next")
        )
    )
    candidates.extend(
        path.relative_to(temporary_repository)
        for path in sorted(temporary_repository.glob("users/*/id_age.pub.next"))
    )
    candidates.extend(
        path.relative_to(temporary_repository)
        for path in sorted(temporary_repository.glob("users/*/id_ed25519.pub.next"))
    )

    for path in sorted(generated_union.rglob("*.age")):
        relative = path.relative_to(generated_union)
        if not (production_repository / relative).exists():
            candidates.append(relative)

    for relative in candidates:
        source = (
            generated_union / relative
            if (generated_union / relative).is_file()
            else temporary_repository / relative
        )
        target = staging / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    return sorted(set(candidates), key=lambda path: path.as_posix())


def evaluate_hosts(repository: Path, hosts: set[str]) -> None:
    for host in sorted(hosts):
        run(
            [
                "nix",
                "eval",
                "--raw",
                f"path:{repository}#nixosConfigurations.{host}.config.system.build.toplevel.outPath",
            ],
            cwd=repository,
            capture=True,
        )


def write_artifact_manifest(
    staging: Path,
    next_index: int,
    source_hashes: dict[str, str],
    artifacts: list[Path],
    hosts: set[str],
) -> Path:
    value = {
        "schema": 1,
        "recoveryIndex": next_index,
        "sourceSecrets": source_hashes,
        "artifacts": {path.as_posix(): sha256(staging / path) for path in artifacts},
        "hosts": sorted(hosts),
    }
    path = staging / "secrets/rotation/next/artifacts.json"
    atomic_write_manifest(path, value)
    return path


def install_artifacts(
    repository: Path,
    staging: Path,
    artifact_paths: list[Path],
    journal: Path,
    runtime_next: Path,
    runtime_created: bool,
) -> None:
    all_paths = [*artifact_paths, Path("secrets/rotation/next/artifacts.json")]
    for relative in all_paths:
        if (repository / relative).exists():
            raise ArtifactError(f"rotation artifact already exists: {relative}")

    journal_value = {
        "schema": 1,
        "status": "installing",
        "runtimeNext": str(runtime_next) if runtime_created else None,
        "artifacts": {
            relative.as_posix(): sha256(staging / relative) for relative in all_paths
        },
    }
    atomic_write_manifest(journal, journal_value)

    fail_after = int(os.environ.get("IDENTITY_ROTATION_FAIL_AFTER", "0"))
    for count, relative in enumerate(all_paths, start=1):
        source = staging / relative
        target = repository / relative
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
        if fail_after == count:
            raise ArtifactError(f"injected failure after artifact {count}")


def verify_hashes(repository: Path, values: dict[str, str], label: str) -> None:
    for relative, expected_hash in values.items():
        path = repository / relative
        if not path.is_file() or sha256(path) != expected_hash:
            raise ArtifactError(f"{label} hash mismatch: {relative}")


def recover(repository: Path, manifest_path: Path, marker: Path, journal: Path) -> None:
    if not journal.is_file():
        raise ArtifactError(f"no artifact transaction journal found: {journal}")
    transaction = json.loads(journal.read_text())
    state = load_manifest(manifest_path)
    artifacts = transaction.get("artifacts", {})
    if state["status"] == "active":
        verify_hashes(repository, artifacts, "prepared artifact")
        journal.unlink()
        print("identity rotation artifact transaction completed")
        return
    if state["status"] != "idle":
        raise ArtifactError("cannot recover artifacts from an unknown rotation state")

    for relative, expected_hash in artifacts.items():
        path = repository / relative
        if not path.exists():
            continue
        if sha256(path) != expected_hash:
            raise ArtifactError(f"refusing to remove changed artifact: {relative}")
        path.unlink()
    runtime_next = transaction.get("runtimeNext")
    if runtime_next:
        Path(runtime_next).unlink(missing_ok=True)
    marker.unlink(missing_ok=True)
    journal.unlink()
    print("identity rotation artifact transaction rolled back")


def command_prepare(args: argparse.Namespace) -> None:
    repository = args.repository.resolve()
    args.manifest = (
        (repository / args.manifest).resolve()
        if not args.manifest.is_absolute()
        else args.manifest
    )
    args.marker = (
        (repository / args.marker).resolve()
        if not args.marker.is_absolute()
        else args.marker
    )
    args.journal = (
        (repository / args.journal).resolve()
        if not args.journal.is_absolute()
        else args.journal
    )
    args.state_script = args.state_script.resolve()
    args.root_file = args.root_file.resolve()
    args.runtime_next = args.runtime_next.resolve()
    require_clean_repository(repository)
    state = load_manifest(args.manifest)
    expected = discover_targets(repository)
    validate_state(
        state,
        expected_targets=expected,
        derivation_index=args.derivation_index,
        marker_active=False,
    )
    if state["status"] != "idle":
        raise ArtifactError("artifact preparation requires idle rotation state")
    if args.journal.exists():
        raise ArtifactError("recover the existing artifact transaction first")

    root = args.root_file.read_text().strip().lower()
    if len(root) != 64 or any(
        character not in "0123456789abcdef" for character in root
    ):
        raise ArtifactError("next root must be canonical 32-byte hexadecimal input")

    runtime_created = False
    with tempfile.TemporaryDirectory(
        prefix="identity-rotation-artifacts."
    ) as directory:
        work = Path(directory)
        temporary_repository = work / "repository"
        copy_tracked_repository(repository, temporary_repository)
        temporary_state = temporary_repository / args.manifest.relative_to(repository)
        temporary_marker = temporary_repository / args.marker.relative_to(repository)
        temporary_expected = discover_targets(temporary_repository)
        master_identity = write_next_identities(
            temporary_repository,
            root,
            args.next_index,
            temporary_expected,
            test_mode=args.test_mode,
        )

        current_master = temporary_repository / "secrets/id_age.pub"
        next_master = temporary_repository / "secrets/rotation/next/id_age.pub"
        if current_master.read_text().strip() == next_master.read_text().strip():
            raise ArtifactError("next master recipient matches the current recipient")

        if not args.test_mode:
            if args.runtime_next.exists():
                raise ArtifactError(
                    f"next runtime identity already exists: {args.runtime_next}"
                )
            args.runtime_next.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(master_identity, args.runtime_next)
            args.runtime_next.chmod(0o600)
            runtime_created = True

        current_slot = work / "current"
        next_slot = work / "next"
        generate_slot(
            temporary_repository,
            temporary_state,
            temporary_marker,
            active_state(state, args.next_index, "current"),
            current_slot,
            args.system,
            dummy=args.test_mode,
        )
        generate_slot(
            temporary_repository,
            temporary_state,
            temporary_marker,
            active_state(state, args.next_index, "next"),
            next_slot,
            args.system,
            dummy=args.test_mode,
        )

        generated_union = work / "union"
        merge_generated([current_slot, next_slot], generated_union)
        for category in ("nixos", "home"):
            union_dir = generated_union / "secrets" / category
            target_dir = temporary_repository / "secrets" / category
            if union_dir.is_dir():
                shutil.copytree(union_dir, target_dir, dirs_exist_ok=True)

        staging = work / "staging"
        artifact_paths = copy_candidate_artifacts(
            temporary_repository, repository, generated_union, staging
        )
        artifact_manifest = write_artifact_manifest(
            staging,
            args.next_index,
            source_secret_hashes(repository),
            artifact_paths,
            expected["nixos"],
        )
        shutil.copy2(
            artifact_manifest,
            temporary_repository / "secrets/rotation/next/artifacts.json",
        )

        atomic_write_manifest(
            temporary_state, active_state(state, args.next_index, "current")
        )
        evaluate_hosts(temporary_repository, expected["nixos"])
        atomic_write_manifest(
            temporary_state, active_state(state, args.next_index, "next")
        )
        evaluate_hosts(temporary_repository, expected["nixos"])

        try:
            install_artifacts(
                repository,
                staging,
                artifact_paths,
                args.journal,
                args.runtime_next,
                runtime_created,
            )
            run(
                [
                    "python3",
                    str(args.state_script),
                    "prepare",
                    str(args.manifest),
                    "--repository",
                    str(repository),
                    "--derivation-index",
                    str(args.derivation_index),
                    "--marker",
                    str(args.marker),
                    str(args.next_index),
                ],
                cwd=repository,
            )
            args.journal.unlink()
        except Exception:
            if args.journal.exists():
                recover(repository, args.manifest, args.marker, args.journal)
            elif runtime_created:
                args.runtime_next.unlink(missing_ok=True)
            raise

    print("identity rotation fleet artifacts prepared")


def command_recover(args: argparse.Namespace) -> None:
    repository = args.repository.resolve()
    manifest = (
        (repository / args.manifest).resolve()
        if not args.manifest.is_absolute()
        else args.manifest
    )
    marker = (
        (repository / args.marker).resolve()
        if not args.marker.is_absolute()
        else args.marker
    )
    journal = (
        (repository / args.journal).resolve()
        if not args.journal.is_absolute()
        else args.journal
    )
    recover(repository, manifest, marker, journal)


def command_paths(args: argparse.Namespace) -> None:
    value = load_manifest(args.manifest)
    for path in sorted(value["artifacts"]):
        print(path)
    print(args.manifest.as_posix())


def command_cleanup(args: argparse.Namespace) -> None:
    repository = args.repository.resolve()
    state_path = (
        (repository / args.state).resolve()
        if not args.state.is_absolute()
        else args.state
    )
    marker = (
        (repository / args.marker).resolve()
        if not args.marker.is_absolute()
        else args.marker
    )
    journal = (
        (repository / args.journal).resolve()
        if not args.journal.is_absolute()
        else args.journal
    )
    artifact_manifest = repository / "secrets/rotation/next/artifacts.json"
    state = load_manifest(state_path)
    if state["status"] != "idle" or marker.exists() or journal.exists():
        raise ArtifactError("artifact cleanup requires unguarded idle rotation state")
    value = load_manifest(artifact_manifest)
    validate_artifact_manifest(
        repository, discover_targets(repository), value["recoveryIndex"]
    )
    for relative in value["artifacts"]:
        (repository / relative).unlink()
    artifact_manifest.unlink()
    args.runtime_next.unlink(missing_ok=True)
    next_directory = repository / "secrets/rotation/next"
    if next_directory.is_dir() and not any(next_directory.iterdir()):
        next_directory.rmdir()
    print("identity rotation prepared artifacts removed")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)

    prepare = commands.add_parser("prepare")
    prepare.add_argument("--repository", type=Path, required=True)
    prepare.add_argument("--manifest", type=Path, required=True)
    prepare.add_argument("--marker", type=Path, required=True)
    prepare.add_argument("--journal", type=Path, required=True)
    prepare.add_argument("--state-script", type=Path, required=True)
    prepare.add_argument("--derivation-index", type=int, required=True)
    prepare.add_argument("--next-index", type=int, required=True)
    prepare.add_argument("--root-file", type=Path, required=True)
    prepare.add_argument("--runtime-next", type=Path, required=True)
    prepare.add_argument("--system", required=True)
    prepare.add_argument("--test-mode", action="store_true", help=argparse.SUPPRESS)
    prepare.set_defaults(run=command_prepare)

    recover_command = commands.add_parser("recover")
    recover_command.add_argument("--repository", type=Path, required=True)
    recover_command.add_argument("--manifest", type=Path, required=True)
    recover_command.add_argument("--marker", type=Path, required=True)
    recover_command.add_argument("--journal", type=Path, required=True)
    recover_command.set_defaults(run=command_recover)

    paths = commands.add_parser("paths")
    paths.add_argument("manifest", type=Path)
    paths.set_defaults(run=command_paths)

    cleanup = commands.add_parser("cleanup")
    cleanup.add_argument("--repository", type=Path, required=True)
    cleanup.add_argument("--state", type=Path, required=True)
    cleanup.add_argument("--marker", type=Path, required=True)
    cleanup.add_argument("--journal", type=Path, required=True)
    cleanup.add_argument("--runtime-next", type=Path, required=True)
    cleanup.set_defaults(run=command_cleanup)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.run(args)
    except (
        ArtifactError,
        RotationError,
        OSError,
        subprocess.CalledProcessError,
    ) as error:
        print(f"identity rotation artifact error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
