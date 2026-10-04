#!/usr/bin/env python3
"""Regression checks for host-only exclusions, without generating real keys."""

import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path

repository = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
# Load the repository tool without relying on the operator's PYTHONPATH.
spec = importlib.util.spec_from_file_location(
    "identity_rotation", repository / "secrets/rotation/identity_rotation.py"
)
assert spec is not None and spec.loader is not None
rotation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rotation)
discover_targets = rotation.discover_targets

with tempfile.TemporaryDirectory(prefix="dot-identity-scope-") as temporary:
    root = Path(temporary)
    (root / "users").mkdir()
    for name in ("fleet", "dot"):
        host = root / "hosts" / name
        host.mkdir(parents=True)
        (host / "configuration.nix").touch()
        (host / "ssh_host_ed25519_key.pub").write_text("keep-me\n")
    marker = root / "hosts/dot/fleet-root-independent"
    marker.touch()
    assert discover_targets(root)["nixos"] == {"fleet"}
    marker.unlink()
    assert discover_targets(root)["nixos"] == {"fleet", "dot"}
    marker.touch()

    # Run the actual wrapper's host loop with inert tool stubs.
    source = (repository / "packages/nixos/nixos.sh").read_text()
    start = source.index(
        "  for host in $(dirs hosts | grep -v iso); do",
        source.index("nixos_generate()"),
    )
    end = source.index("  for user in $(dirs users); do", start)
    script = """set -euo pipefail
    dirs() { printf 'dot\\nfleet\\n'; }
    agenix() { printf 'dummy-root\\n'; }
    derive() { printf 'dummy-public\\n'; }
    git() { :; }
    gum_show() { :; }
    """ + source[start:end]
    subprocess.run(["bash", "-c", script], cwd=root, check=True)
    assert (root / "hosts/dot/ssh_host_ed25519_key.pub").read_text() == "keep-me\n"
    assert (
        root / "hosts/fleet/ssh_host_ed25519_key.pub"
    ).read_text() == "dummy-public\n"

assert "dot" not in discover_targets(repository)["nixos"]
print(
    "PASS: host-only keys excluded from fleet generation and rotation; fleet behavior preserved"
)
