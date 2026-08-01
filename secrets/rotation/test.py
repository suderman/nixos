#!/usr/bin/env python3
"""Exercise the inert two-target identity rotation scaffold."""

from __future__ import annotations

import copy
import json
import os
import subprocess
import tempfile
from argparse import Namespace
from pathlib import Path

from identity_rotation import (
    RotationError,
    atomic_write_manifest,
    command_cancel,
    command_move,
    command_prepare,
    create_marker,
    parser,
    validate_state,
    validate_transition,
)


HERE = Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"
DERIVE = os.environ["DERIVE_BIN"]
TARGETS = {
    "home": set(),
    "identities": set(),
    "nixos": {"alpha", "beta"},
}


def derive(value: str, *arguments: str) -> str:
    result = subprocess.run(
        [DERIVE, *arguments],
        input=value,
        capture_output=True,
        check=True,
        text=True,
    )
    return result.stdout.strip()


def fixture_state(
    *, status: str = "idle", current_index: int = 1, next_index: int | None = None
) -> dict:
    return {
        "schema": 1,
        "status": status,
        "currentIndex": current_index,
        "nextIndex": next_index,
        "targets": {
            "home": {},
            "identities": {},
            "nixos": {"alpha": "current", "beta": "current"},
        },
    }


def moved(state: dict, target: str, target_state: str) -> dict:
    result = copy.deepcopy(state)
    result["targets"]["nixos"][target] = target_state
    return result


def expect_invalid(action, message: str) -> None:
    try:
        action()
    except RotationError:
        return
    raise AssertionError(message)


def verify_vectors(work_dir: Path) -> None:
    roots = {
        "current": (FIXTURES / "current.hex").read_text().strip(),
        "next": (FIXTURES / "next.hex").read_text().strip(),
    }
    vectors = json.loads((FIXTURES / "vectors.json").read_text())

    assert roots["current"] != roots["next"]
    assert all(len(root) == 64 and root == root.lower() for root in roots.values())

    for slot, root in roots.items():
        for target in ("alpha", "beta"):
            child = derive(root, "hex", target)
            ssh_private = derive(child, "ssh")
            age_private = derive(child, "age")
            actual = {
                "ageRecipient": derive(age_private, "public"),
                "machineId": derive(root, "hex", target, "32"),
                "sshPublic": derive(ssh_private, "public"),
            }
            assert actual == vectors[slot][target]

            artifact_dir = work_dir / target / slot
            artifact_dir.mkdir(parents=True)
            for name, value in actual.items():
                (artifact_dir / name).write_text(f"{value}\n")

    assert vectors["current"]["alpha"] != vectors["next"]["alpha"]
    assert vectors["current"]["beta"] != vectors["next"]["beta"]


def verify_transitions() -> None:
    idle = fixture_state()
    prepared = fixture_state(status="active", next_index=2)
    partial = moved(prepared, "alpha", "bridge")
    rolled_back = moved(partial, "alpha", "current")
    resumed = moved(rolled_back, "alpha", "bridge")
    alpha_next = moved(resumed, "alpha", "next")
    beta_bridge = moved(alpha_next, "beta", "bridge")
    all_next = moved(beta_bridge, "beta", "next")
    finalized = fixture_state(current_index=2)

    validate_state(
        idle, expected_targets=TARGETS, derivation_index=1, marker_active=False
    )
    for state in (
        prepared,
        partial,
        rolled_back,
        resumed,
        alpha_next,
        beta_bridge,
        all_next,
    ):
        validate_state(state, expected_targets=TARGETS, marker_active=True)
    validate_state(
        finalized, expected_targets=TARGETS, derivation_index=2, marker_active=False
    )

    sequence = (
        (idle, prepared),
        (prepared, partial),
        (partial, rolled_back),
        (rolled_back, resumed),
        (resumed, alpha_next),
        (alpha_next, beta_bridge),
        (beta_bridge, all_next),
        (all_next, finalized),
    )
    for before, after in sequence:
        validate_transition(before, after)
    validate_transition(rolled_back, idle)

    skipped_bridge = moved(prepared, "alpha", "next")
    expect_invalid(
        lambda: validate_transition(prepared, skipped_bridge),
        "current-to-next transition bypassed bridge",
    )
    expect_invalid(
        lambda: validate_transition(alpha_next, finalized),
        "partially migrated state finalized",
    )
    expect_invalid(
        lambda: validate_state(prepared, expected_targets=TARGETS, marker_active=False),
        "active state passed without ACTIVE marker",
    )
    expect_invalid(
        lambda: validate_state(idle, expected_targets=TARGETS, marker_active=True),
        "idle state passed with ACTIVE marker",
    )

    missing_target = copy.deepcopy(idle)
    del missing_target["targets"]["nixos"]["beta"]
    expect_invalid(
        lambda: validate_state(missing_target, expected_targets=TARGETS),
        "manifest omitted an expected target",
    )

    stale_target = copy.deepcopy(idle)
    stale_target["targets"]["nixos"]["retired"] = "current"
    expect_invalid(
        lambda: validate_state(stale_target, expected_targets=TARGETS),
        "manifest retained a stale target",
    )


def write_artifact(path: Path, value: str = "test artifact") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"{value}\n")


def write_age_ciphertext(path: Path) -> None:
    write_artifact(path, "age-encryption.org/v1\nfixture ciphertext")


def managed_fixture(repository: Path) -> tuple[Path, Path]:
    vectors = json.loads((FIXTURES / "vectors.json").read_text())
    for host in ("alpha", "beta"):
        write_artifact(repository / f"hosts/{host}/configuration.nix")
        write_artifact(
            repository / f"hosts/{host}/ssh_host_ed25519_key.pub",
            vectors["current"][host]["sshPublic"],
        )
        write_artifact(
            repository / f"hosts/{host}/ssh_host_ed25519_key.pub.next",
            vectors["next"][host]["sshPublic"],
        )
        write_age_ciphertext(repository / f"secrets/nixos/{host}/fixture-hex-next.age")

    write_artifact(repository / "hosts/alpha/users/alice.nix")
    write_artifact(repository / "users/alice/default.nix")
    write_artifact(
        repository / "users/alice/id_age.pub",
        vectors["current"]["beta"]["ageRecipient"],
    )
    write_artifact(
        repository / "users/alice/id_age.pub.next",
        vectors["next"]["beta"]["ageRecipient"],
    )
    write_artifact(
        repository / "users/alice/id_ed25519.pub",
        vectors["current"]["beta"]["sshPublic"],
    )
    write_artifact(
        repository / "users/alice/id_ed25519.pub.next",
        vectors["next"]["beta"]["sshPublic"],
    )

    write_artifact(
        repository / "secrets/id_age.pub",
        vectors["current"]["alpha"]["ageRecipient"],
    )
    write_age_ciphertext(repository / "secrets/rotation/next/hex.age")
    write_age_ciphertext(repository / "secrets/rotation/next/id_age.age")
    write_artifact(
        repository / "secrets/rotation/next/id_age.pub",
        vectors["next"]["alpha"]["ageRecipient"],
    )

    manifest = repository / "secrets/rotation/state.json"
    marker = repository / "secrets/rotation/ACTIVE"
    state = {
        "schema": 1,
        "status": "idle",
        "currentIndex": 1,
        "nextIndex": None,
        "targets": {
            "home": {"alpha-alice": "current"},
            "identities": {"alice": "current"},
            "nixos": {"alpha": "current", "beta": "current"},
        },
    }
    atomic_write_manifest(manifest, state)
    return manifest, marker


def managed_args(repository: Path, manifest: Path, marker: Path, **values) -> Namespace:
    return Namespace(
        repository=repository,
        manifest=manifest,
        marker=marker,
        derivation_index=1,
        **values,
    )


def verify_managed_state() -> None:
    with tempfile.TemporaryDirectory(prefix="identity-rotation-managed.") as directory:
        repository = Path(directory)
        manifest, marker = managed_fixture(repository)
        prepare = managed_args(repository, manifest, marker, next_index=2)

        missing_artifact = repository / "users/alice/id_age.pub.next"
        saved_artifact = missing_artifact.read_text()
        missing_artifact.unlink()
        original_manifest = manifest.read_bytes()
        expect_invalid(
            lambda: command_prepare(prepare),
            "managed prepare accepted an incomplete artifact set",
        )
        assert manifest.read_bytes() == original_manifest
        assert not marker.exists()
        missing_artifact.write_text(saved_artifact)

        invalid_public = repository / "hosts/alpha/ssh_host_ed25519_key.pub.next"
        saved_public = invalid_public.read_text()
        invalid_public.write_text("not an SSH public key\n")
        expect_invalid(
            lambda: command_prepare(prepare),
            "managed prepare accepted malformed public material",
        )
        assert manifest.read_bytes() == original_manifest
        assert not marker.exists()
        invalid_public.write_text(saved_public)

        parsed = parser().parse_args(
            [
                "prepare",
                str(manifest),
                "--repository",
                str(repository),
                "--derivation-index",
                "1",
                "--marker",
                str(marker),
                "2",
            ]
        )
        assert parsed.next_index == 2

        command_prepare(prepare)
        prepared = json.loads(manifest.read_text())
        assert prepared["status"] == "active"
        assert prepared["nextIndex"] == 2
        assert marker.read_text() == "identity rotation active: 1 -> 2\n"

        skipped = managed_args(
            repository,
            manifest,
            marker,
            category="nixos",
            name="alpha",
            target_state="next",
        )
        prepared_manifest = manifest.read_bytes()
        expect_invalid(
            lambda: command_move(skipped),
            "managed move bypassed bridge",
        )
        assert manifest.read_bytes() == prepared_manifest

        bridge = managed_args(
            repository,
            manifest,
            marker,
            category="nixos",
            name="alpha",
            target_state="bridge",
        )
        command_move(bridge)
        expect_invalid(
            lambda: command_cancel(managed_args(repository, manifest, marker)),
            "managed cancel accepted a partially migrated state",
        )
        assert marker.exists()

        bridge.target_state = "current"
        command_move(bridge)
        command_cancel(managed_args(repository, manifest, marker))
        assert json.loads(manifest.read_text())["status"] == "idle"
        assert not marker.exists()

        create_marker(marker, 1, 2)
        command_cancel(managed_args(repository, manifest, marker))
        assert not marker.exists()


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="identity-rotation-test.") as directory:
        verify_vectors(Path(directory))
    verify_transitions()
    verify_managed_state()
    print("identity rotation simulation passed")


if __name__ == "__main__":
    main()
