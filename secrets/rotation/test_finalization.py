#!/usr/bin/env python3
"""Transaction tests for identity rotation finalization."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from argparse import Namespace
from pathlib import Path

import identity_artifacts
import identity_finalization
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


def age_encrypt(value: str, recipient: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["age", "--encrypt", "--recipient", recipient, "--output", str(path)],
        input=value.encode(),
        check=True,
    )


def age_decrypt(path: Path, identity: Path) -> str:
    return subprocess.run(
        ["age", "--decrypt", "--identity", str(identity), str(path)],
        check=True,
        stdout=subprocess.PIPE,
    ).stdout.decode()


def git(repository: Path, *arguments: str) -> None:
    subprocess.run(["git", *arguments], cwd=repository, check=True)


def commit(repository: Path, message: str) -> None:
    git(repository, "add", "-A")
    git(
        repository,
        "-c",
        "user.name=rotation-test",
        "-c",
        "user.email=rotation@example.invalid",
        "commit",
        "--quiet",
        "-m",
        message,
    )


def initialize_lifecycle_repository(repository: Path, current_root: str) -> str:
    current_master = derive(current_root, "age")
    current_recipient = derive(current_master, "public")
    host_private = derive(derive(current_root, "hex", "alpha"), "ssh")
    user_seed = derive(current_root, "hex", "alice")

    write(repository / ".gitignore", "secrets/id_age.age\n")
    write(repository / "flake.nix", "{ derivationIndex = 1; }\n")
    write(repository / "hosts/alpha/configuration.nix", "{}\n")
    write(
        repository / "hosts/alpha/ssh_host_ed25519_key.pub",
        f"{derive(host_private, 'public')}\n",
    )
    write(repository / "hosts/alpha/users/alice.nix", "{}\n")
    write(repository / "users/alice/default.nix", "{}\n")
    write(
        repository / "users/alice/id_age.pub",
        f"{derive(derive(user_seed, 'age'), 'public')}\n",
    )
    write(
        repository / "users/alice/id_ed25519.pub",
        f"{derive(derive(user_seed, 'ssh'), 'public')}\n",
    )
    write(repository / "secrets/id_age.pub", f"{current_recipient}\n")
    write(
        repository / "secrets/default.nix",
        """{
  masterIdentities =
          [/tmp/id_age /tmp/id_age_]
          ++ lib.optional rotationActive /tmp/id_age_next;
}
""",
    )
    age_encrypt(current_root, current_recipient, repository / "secrets/hex.age")
    age_encrypt(
        "lifecycle secret\n",
        current_recipient,
        repository / "users/alice/password.age",
    )
    age_encrypt(current_master, current_recipient, repository / "secrets/id_age.age")
    atomic_write_manifest(
        repository / "secrets/rotation/state.json",
        {
            "schema": 1,
            "status": "idle",
            "currentIndex": 1,
            "nextIndex": None,
            "preparedHosts": [],
            "nextHosts": [],
            "targets": {
                "home": {"alpha-alice": "current"},
                "identities": {"alice": "current"},
                "nixos": {"alpha": "current"},
            },
        },
    )
    git(repository, "init", "--quiet")
    commit(repository, "fixture")
    return current_master


def write_fake_rekey(path: Path) -> None:
    write(
        path,
        f"""#!{sys.executable}
import json
from pathlib import Path

root = Path.cwd()
state = json.loads((root / "secrets/rotation/state.json").read_text())
if (root / "secrets/rotation/ACTIVE").exists():
    name = state["targets"]["nixos"]["alpha"] + "-hex-next.age"
else:
    name = "final.age"
path = root / "secrets/nixos/alpha" / name
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text("age-encryption.org/v1\\nfixture ciphertext\\n")
""",
    )
    path.chmod(0o755)


def verify_lifecycle() -> None:
    current_root = (FIXTURES / "current.hex").read_text().strip()
    next_root = (FIXTURES / "next.hex").read_text().strip()
    next_master = derive(next_root, "age")

    with tempfile.TemporaryDirectory(prefix="identity-rotation-lifecycle.") as value:
        root = Path(value)
        repository = root / "repository"
        repository.mkdir()
        current_master = initialize_lifecycle_repository(repository, current_root)
        fake_rekey = root / "rekey"
        write_fake_rekey(fake_rekey)
        identity_artifacts.build_rekey_package = lambda *_: fake_rekey
        identity_artifacts.evaluate_hosts = lambda *_: None
        identity_finalization.build_rekey_package = lambda *_: fake_rekey
        identity_finalization.evaluate_hosts = lambda *_: None

        root_file = root / "next.hex"
        write(root_file, f"{next_root}\n")
        runtime_current = root / "runtime/current"
        runtime_next = root / "runtime/next"
        write(runtime_current, f"{current_master}\n")
        write(runtime_next, f"{next_master}\n")

        identity_artifacts.command_prepare(
            Namespace(
                repository=repository,
                manifest=Path("secrets/rotation/state.json"),
                marker=Path("secrets/rotation/ACTIVE"),
                journal=Path("secrets/rotation/PREPARE.json"),
                state_script=Path(__file__).parent / "identity_rotation.py",
                derivation_index=1,
                next_index=2,
                root_file=root_file,
                runtime_next=runtime_next,
                system="x86_64-linux",
                test_mode=True,
            )
        )

        state_path = repository / "secrets/rotation/state.json"
        state = json.loads(state_path.read_text())
        state["preparedHosts"] = ["alpha"]
        state["nextHosts"] = ["alpha"]
        for category in state["targets"].values():
            for target in category:
                category[target] = "next"
        atomic_write_manifest(state_path, state)
        commit(repository, "prepared next generation")

        identity_finalization.command_finalize(
            Namespace(
                repository=repository,
                manifest=Path("secrets/rotation/state.json"),
                marker=Path("secrets/rotation/ACTIVE"),
                journal=Path("secrets/rotation/FINALIZE.json"),
                backup=Path("secrets/rotation/finalize-backup"),
                derivation_index=1,
                system="x86_64-linux",
                paths_output=root / "changed-paths",
                runtime_current=runtime_current,
                runtime_previous=root / "runtime/previous",
                runtime_next=runtime_next,
            )
        )

        final_state = json.loads(state_path.read_text())
        assert final_state["status"] == "idle"
        assert final_state["currentIndex"] == 2
        assert not (repository / "secrets/rotation/ACTIVE").exists()
        assert (
            age_decrypt(repository / "users/alice/password.age", runtime_current)
            == "lifecycle secret\n"
        )
        assert (
            age_decrypt(repository / "secrets/hex.age", runtime_current).strip()
            == next_root
        )
        assert derive(runtime_current.read_text(), "public") == derive(
            next_master, "public"
        )
        assert not runtime_next.exists()
        assert not (repository / "secrets/rotation/FINALIZE.json").exists()


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

    verify_lifecycle()
    print("identity rotation finalization tests passed")


if __name__ == "__main__":
    main()
