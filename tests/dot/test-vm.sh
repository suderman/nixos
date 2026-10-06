#!/usr/bin/env bash
# Run from nix develop. Uses KVM, 32 GiB sparse disk, dummy secrets, loopback SSH only.
set -euo pipefail
export DOT_TEST_REPO
DOT_TEST_REPO=$(git rev-parse --show-toplevel)
cd "$DOT_TEST_REPO"
test -w /dev/kvm
fixture='let f = builtins.getFlake ("git+file://" + builtins.getEnv "DOT_TEST_REPO"); p = f.nixosConfigurations.dot.pkgs; in import (f + /tests/dot/vm-fixture.nix) {flake=f; pkgs=p; lib=p.lib;}'
nix build --impure --expr "builtins.attrValues ($fixture)" --no-link
paths=$(nix eval --impure --json --expr "builtins.mapAttrs (_: v: toString v) ($fixture)")
python=$(jq -r '.tools + "/bin/python3"' <<<"$paths")
exec "$python" tests/dot/test-vm.py "$paths"
