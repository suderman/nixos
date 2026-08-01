#!/usr/bin/env python3
"""Transaction-only tests for identity artifact installation and recovery."""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path

from identity_artifacts import ArtifactError, install_artifacts, recover, sha256
from identity_rotation import atomic_write_manifest


def write(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value)


def state(status: str) -> dict:
    return {
        "schema": 1,
        "status": status,
        "currentIndex": 1,
        "nextIndex": 0 if status == "active" else None,
        "preparedHosts": [],
        "targets": {
            "home": {"alpha-alice": "current"},
            "identities": {"alice": "current"},
            "nixos": {"alpha": "current"},
        },
    }


def fixture(root: Path) -> tuple[Path, Path, list[Path], Path, Path, Path]:
    repository = root / "repository"
    staging = root / "staging"
    manifest = repository / "secrets/rotation/state.json"
    marker = repository / "secrets/rotation/ACTIVE"
    journal = repository / "secrets/rotation/PREPARE.json"
    paths = [Path("hosts/alpha/key.next"), Path("secrets/nixos/alpha/value.age")]
    for relative in paths:
        write(staging / relative, f"fixture:{relative}\n")
    artifact_manifest = staging / "secrets/rotation/next/artifacts.json"
    write(
        artifact_manifest,
        json.dumps(
            {
                "schema": 1,
                "recoveryIndex": 0,
                "sourceSecrets": {},
                "artifacts": {
                    relative.as_posix(): sha256(staging / relative)
                    for relative in paths
                },
                "hosts": ["alpha"],
            }
        ),
    )
    atomic_write_manifest(manifest, state("idle"))
    return repository, staging, paths, manifest, marker, journal


def assert_absent(repository: Path, paths: list[Path], journal: Path) -> None:
    assert not journal.exists()
    assert not (repository / "secrets/rotation/next/artifacts.json").exists()
    assert all(not (repository / relative).exists() for relative in paths)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="identity-artifact-transactions.") as value:
        root = Path(value)

        repository, staging, paths, manifest, marker, journal = fixture(root / "fail")
        os.environ["IDENTITY_ROTATION_FAIL_AFTER"] = "2"
        try:
            install_artifacts(
                repository, staging, paths, journal, root / "runtime-next", False
            )
        except ArtifactError:
            pass
        else:
            raise AssertionError("injected artifact installation failure succeeded")
        finally:
            os.environ.pop("IDENTITY_ROTATION_FAIL_AFTER", None)
        recover(repository, manifest, marker, journal)
        assert_absent(repository, paths, journal)

        repository, staging, paths, manifest, marker, journal = fixture(root / "active")
        install_artifacts(
            repository, staging, paths, journal, root / "runtime-next", False
        )
        atomic_write_manifest(manifest, state("active"))
        marker.write_text("active\n")
        recover(repository, manifest, marker, journal)
        assert not journal.exists()
        assert all((repository / relative).is_file() for relative in paths)

        repository, staging, paths, manifest, marker, journal = fixture(
            root / "changed"
        )
        install_artifacts(
            repository, staging, paths, journal, root / "runtime-next", False
        )
        (repository / paths[0]).write_text("operator change\n")
        try:
            recover(repository, manifest, marker, journal)
        except ArtifactError:
            pass
        else:
            raise AssertionError("recovery removed a changed artifact")
        assert journal.exists()
        assert (repository / paths[0]).read_text() == "operator change\n"

    print("identity rotation artifact transaction tests passed")


if __name__ == "__main__":
    main()
