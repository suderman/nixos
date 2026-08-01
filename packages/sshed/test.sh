#!/usr/bin/env bash
set -euo pipefail

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

current_root=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
next_root=202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f

derive_key_pair() {
  local root="$1" name="$2"
  derive hex alpha <<<"$root" | derive ssh >"$work_dir/$name"
  derive public <"$work_dir/$name" >"$work_dir/$name.pub"
}

derive_key_pair "$current_root" current
derive_key_pair "$next_root" next

"$SSHED_BIN" verify-pair "$work_dir/current" "$work_dir/current.pub"
"$SSHED_BIN" verify-pair "$work_dir/next" "$work_dir/next.pub"

if "$SSHED_BIN" verify-pair "$work_dir/current" "$work_dir/next.pub"; then
  echo "sshed accepted a mismatched explicit key pair" >&2
  exit 1
fi

mkdir "$work_dir/directory"
cp "$work_dir/current" "$work_dir/directory/id_ed25519"
cp "$work_dir/current.pub" "$work_dir/directory/id_ed25519.pub"
"$SSHED_BIN" verify "$work_dir/directory"

echo "sshed explicit pair tests passed"
