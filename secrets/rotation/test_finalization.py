#!/usr/bin/env python3
"""Transaction tests for identity rotation finalization."""

from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

from identity_finalization import (
    FinalizationError,
    apply_changes,
    finalized_state,
    recover_transaction,
    write_transaction,
)
from identity_rotation import atomic_write_manifest


DERIVE = os.environ["DERIVE_BIN"]
FIXTURES = Path(__file__).parent / "fixtures"


def write(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value)


def derive(value: str, *arguments: str) -> str:
    return subprocess.run(
        [DERIVE, *arguments],
        input=f"{value}\n",
        text=True,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout.strip()


def active_state(target: str = "next") -> dict:
    return {
        "schema": 1,
        "status": "active",
        "currentIndex": 1,
        "nextIndex": 0,
        "preparedHosts": ["alpha"],
        "nextHosts": ["alpha"],
        "targets": {
            "home": {"alpha-alice": target},
            "identities": {"alice": target},
            "nixos": {"alpha": target},
        },
    }


def fixture(root: Path):
    repository = root / "repository"
    staging = root / "staging"
    journal = repository / "secrets/rotation/FINALIZE.json"
    backup = repository / "secrets/rotation/finalize-backup"
    runtime = root / "runtime"
    runtime.mkdir(parents=True)

    write(repository / "replace", "before replace\n")
    write(repository / "remove", "before remove\n")
    write(staging / "replace", "after replace\n")
    write(staging / "add", "after add\n")
    changes = {
        Path("replace"): staging / "replace",
        Path("remove"): None,
        Path("add"): staging / "add",
    }
    return repository, changes, journal, backup, runtime


def assert_before(repository: Path) -> None:
    assert (repository / "replace").read_text() == "before replace\n"
    assert (repository / "remove").read_text() == "before remove\n"
    assert not (repository / "add").exists()


def main() -> None:
    finalized = finalized_state(active_state())
    assert finalized["status"] == "idle"
    assert finalized["currentIndex"] == 0
    assert finalized["nextIndex"] is None
    assert finalized["preparedHosts"] == []
    assert finalized["nextHosts"] == []
    assert set(finalized["targets"]["nixos"].values()) == {"current"}

    partial = active_state()
    partial["targets"]["home"]["alpha-alice"] = "bridge"
    try:
        finalized_state(partial)
    except FinalizationError:
        pass
    else:
        raise AssertionError("partial migration was finalized")

    unattested = active_state()
    unattested["nextHosts"] = []
    try:
        finalized_state(unattested)
    except FinalizationError:
        pass
    else:
        raise AssertionError("unattested all-next migration was finalized")

    with tempfile.TemporaryDirectory(prefix="identity-finalization-tests.") as value:
        root = Path(value)

        repository, changes, journal, backup, runtime = fixture(root / "failure")
        transaction = write_transaction(repository, changes, journal, backup)
        os.environ["IDENTITY_ROTATION_FINALIZE_FAIL_AFTER"] = "2"
        try:
            apply_changes(repository, changes, transaction, journal)
        except FinalizationError:
            pass
        else:
            raise AssertionError("injected finalization failure succeeded")
        finally:
            os.environ.pop("IDENTITY_ROTATION_FINALIZE_FAIL_AFTER", None)
        recover_transaction(
            repository,
            journal,
            backup,
            runtime / "current",
            runtime / "previous",
            runtime / "next",
        )
        assert_before(repository)
        assert not journal.exists()
        assert not backup.exists()

        repository, changes, journal, backup, runtime = fixture(root / "changed")
        transaction = write_transaction(repository, changes, journal, backup)
        os.environ["IDENTITY_ROTATION_FINALIZE_FAIL_AFTER"] = "1"
        try:
            apply_changes(repository, changes, transaction, journal)
        except FinalizationError:
            pass
        finally:
            os.environ.pop("IDENTITY_ROTATION_FINALIZE_FAIL_AFTER", None)
        (repository / "add").write_text("operator change\n")
        try:
            recover_transaction(
                repository,
                journal,
                backup,
                runtime / "current",
                runtime / "previous",
                runtime / "next",
            )
        except FinalizationError:
            pass
        else:
            raise AssertionError("recovery overwrote an operator change")
        assert journal.exists()

        repository, changes, journal, backup, runtime = fixture(root / "committed")
        current_root = (FIXTURES / "current.hex").read_text().strip()
        next_root = (FIXTURES / "next.hex").read_text().strip()
        current_identity = derive(current_root, "age")
        next_identity = derive(next_root, "age")
        write(runtime / "current", f"{current_identity}\n")
        write(runtime / "previous", f"{current_identity}\n")
        write(runtime / "next", f"{next_identity}\n")
        write(
            repository / "secrets/id_age.pub", f"{derive(current_identity, 'public')}\n"
        )
        write(
            staging := root / "committed/staging/id_age.pub",
            f"{derive(next_identity, 'public')}\n",
        )
        changes[Path("secrets/id_age.pub")] = staging

        transaction = write_transaction(repository, changes, journal, backup)
        apply_changes(repository, changes, transaction, journal)
        recover_transaction(
            repository,
            journal,
            backup,
            runtime / "current",
            runtime / "previous",
            runtime / "next",
        )
        assert derive((runtime / "current").read_text(), "public") == derive(
            next_identity, "public"
        )
        assert not (runtime / "previous").exists()
        assert not (runtime / "next").exists()
        assert not journal.exists()
        assert not backup.exists()

        repository, _, journal, backup, runtime = fixture(root / "backing-up")
        backup.mkdir(parents=True)
        atomic_write_manifest(
            journal,
            {
                "schema": 1,
                "status": "backing-up",
                "backup": str(backup),
                "changes": {"replace": {"before": "0" * 64, "after": "1" * 64}},
            },
        )
        recover_transaction(
            repository,
            journal,
            backup,
            runtime / "current",
            runtime / "previous",
            runtime / "next",
        )
        assert not journal.exists()
        assert not backup.exists()

    print("identity rotation finalization transaction tests passed")


if __name__ == "__main__":
    main()
