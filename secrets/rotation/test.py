#!/usr/bin/env python3
"""Exercise the inert two-target identity rotation scaffold."""

from __future__ import annotations

import copy
import json
import os
import subprocess
import tempfile
from pathlib import Path

from identity_rotation import RotationError, validate_state, validate_transition


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


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="identity-rotation-test.") as directory:
        verify_vectors(Path(directory))
    verify_transitions()
    print("identity rotation simulation passed")


if __name__ == "__main__":
    main()
