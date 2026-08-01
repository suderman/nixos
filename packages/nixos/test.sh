#!/usr/bin/env bash
set -euo pipefail

nixos_script="${NIXOS_SCRIPT:?NIXOS_SCRIPT is required}"
bash_bin="${BASH_BIN:?BASH_BIN is required}"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

mock_bin="$test_dir/bin"
rotation_marker="$test_dir/ACTIVE"
mkdir -p "$mock_bin"
touch "$rotation_marker"

printf '#!%s\n' "$bash_bin" >"$mock_bin/gum"
cat >>"$mock_bin/gum" <<'EOF'
set -euo pipefail
if [[ $1 == "style" ]]; then
  printf '%s\n' "${*: -1}"
  exit 0
fi
printf 'FAIL: guarded command reached gum %s\n' "$1" >&2
exit 97
EOF
chmod +x "$mock_bin/gum"

run_nixos() {
  env \
    IDENTITY_ROTATION_MARKER="$rotation_marker" \
    PATH="$mock_bin:$PATH" \
    bash "$nixos_script" "$@"
}

if run_nixos generate >"$test_dir/generate.out" 2>&1; then
  printf 'FAIL: nixos generate ran while identity rotation was active\n' >&2
  exit 1
fi

if run_nixos add host >"$test_dir/add.out" 2>&1; then
  printf 'FAIL: nixos add ran while identity rotation was active\n' >&2
  exit 1
fi
