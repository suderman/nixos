#!/usr/bin/env bash
set -euo pipefail

nixos_script="${NIXOS_SCRIPT:?NIXOS_SCRIPT is required}"
bash_bin="${BASH_BIN:?BASH_BIN is required}"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

mock_bin="$test_dir/bin"
rotation_marker="$test_dir/ACTIVE"
rotation_state="$test_dir/state.json"
rotation_args="$test_dir/rotation.args"
rotation_journal="$test_dir/PREPARE.json"
mkdir -p "$mock_bin"
touch "$rotation_marker"
printf '{}\n' >"$rotation_state"

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

printf '#!%s\n' "$bash_bin" >"$mock_bin/python3"
cat >>"$mock_bin/python3" <<'EOF'
set -euo pipefail
printf '%s\n' "$*" >"$ROTATION_ARGS"
EOF
chmod +x "$mock_bin/python3"

run_nixos() {
  env \
    IDENTITY_ROTATION_MARKER="$rotation_marker" \
    IDENTITY_ROTATION_SCRIPT="$test_dir/identity_rotation.py" \
    IDENTITY_ARTIFACTS_SCRIPT="$test_dir/identity_artifacts.py" \
    IDENTITY_ROTATION_STATE="$rotation_state" \
    IDENTITY_ROTATION_JOURNAL="$rotation_journal" \
    ROTATION_ARGS="$rotation_args" \
    derivation_index=1 \
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

run_nixos rotation status
expected="${test_dir}/identity_rotation.py status ${rotation_state} --repository . --derivation-index 1 --marker ${rotation_marker}"
if [[ $(<"$rotation_args") != "$expected" ]]; then
  printf 'FAIL: nixos rotation status dispatched unexpected arguments\n' >&2
  exit 1
fi

run_nixos rotation recover
expected="${test_dir}/identity_artifacts.py recover --repository . --manifest ${rotation_state} --marker ${rotation_marker} --journal ${rotation_journal}"
if [[ $(<"$rotation_args") != "$expected" ]]; then
  printf 'FAIL: nixos rotation recover dispatched unexpected arguments\n' >&2
  exit 1
fi

if run_nixos rotation finalize >"$test_dir/finalize.out" 2>&1; then
  printf 'FAIL: unsafe identity rotation finalization was available\n' >&2
  exit 1
fi
