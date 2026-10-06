#!/usr/bin/env python3
"""Check that dot participates in normal fleet generation and rotation."""

import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path

repository = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "identity_rotation", repository / "secrets/rotation/identity_rotation.py"
)
assert spec is not None and spec.loader is not None
rotation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rotation)

with tempfile.TemporaryDirectory(prefix="dot-identity-scope-") as temporary:
    root = Path(temporary)
    (root / "users").mkdir()
    for name in ("fleet", "dot"):
        host = root / "hosts" / name
        host.mkdir(parents=True)
        (host / "configuration.nix").touch()
        (host / "ssh_host_ed25519_key.pub").write_text("keep-me\n")
    assert rotation.discover_targets(root)["nixos"] == {"fleet", "dot"}

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
    for name in ("fleet", "dot"):
        assert (
            root / "hosts" / name / "ssh_host_ed25519_key.pub"
        ).read_text() == "dummy-public\n"

targets = rotation.discover_targets(repository)
assert "dot" in targets["nixos"]
assert "dot-jon" in targets["home"]
print("PASS: dot host generation and dot/dot-jon fleet rotation membership")
