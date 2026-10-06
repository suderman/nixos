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
finalization_journal="$test_dir/FINALIZE.json"
finalization_backup="$test_dir/finalize-backup"
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
if [[ $1 == "input" && ${ALLOW_ROTATION_INPUT:-0} == "1" ]]; then
  printf '%064d\n' 0
  exit 0
fi
printf 'FAIL: guarded command reached gum %s\n' "$1" >&2
exit 97
EOF
chmod +x "$mock_bin/gum"

printf '#!%s\n' "$bash_bin" >"$mock_bin/agenix"
cat >>"$mock_bin/agenix" <<'EOF'
set -euo pipefail
[[ ${FAIL_AGENIX:-0} != "1" ]]
EOF
chmod +x "$mock_bin/agenix"

printf '#!%s\n' "$bash_bin" >"$mock_bin/python3"
cat >>"$mock_bin/python3" <<'EOF'
set -euo pipefail
printf '%s\n' "$*" >"$ROTATION_ARGS"
EOF
chmod +x "$mock_bin/python3"

printf '#!%s\n' "$bash_bin" >"$mock_bin/nix"
cat >>"$mock_bin/nix" <<'EOF'
set -euo pipefail
if [[ $1 == "eval" ]]; then
  printf '%s\n' test-next-token
  exit 0
fi
exit 96
EOF
chmod +x "$mock_bin/nix"

printf '#!%s\n' "$bash_bin" >"$mock_bin/hostname"
cat >>"$mock_bin/hostname" <<'EOF'
printf '%s\n' local-test-host
EOF
chmod +x "$mock_bin/hostname"

printf '#!%s\n' "$bash_bin" >"$mock_bin/ssh"
cat >>"$mock_bin/ssh" <<'EOF'
set -euo pipefail
if [[ $* == "alpha cat /run/identity-rotation/next-verified" ]]; then
  printf '%s\n' "${REMOTE_TOKEN:-test-next-token}"
  exit 0
fi
exit 95
EOF
chmod +x "$mock_bin/ssh"

printf '#!%s\n' "$bash_bin" >"$mock_bin/git"
cat >>"$mock_bin/git" <<'EOF'
set -euo pipefail
[[ $1 == "add" ]]
EOF
chmod +x "$mock_bin/git"

run_nixos() {
  env \
    IDENTITY_ROTATION_MARKER="$rotation_marker" \
    IDENTITY_ROTATION_SCRIPT="$test_dir/identity_rotation.py" \
    IDENTITY_ARTIFACTS_SCRIPT="$test_dir/identity_artifacts.py" \
    IDENTITY_FINALIZATION_SCRIPT="$test_dir/identity_finalization.py" \
    IDENTITY_ROTATION_STATE="$rotation_state" \
    IDENTITY_ROTATION_JOURNAL="$rotation_journal" \
    IDENTITY_FINALIZATION_JOURNAL="$finalization_journal" \
    IDENTITY_FINALIZATION_BACKUP="$finalization_backup" \
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

root_tmp="$test_dir/root-tmp"
mkdir "$root_tmp"
if ALLOW_ROTATION_INPUT=1 FAIL_AGENIX=1 TMPDIR="$root_tmp" \
  run_nixos rotation prepare 2 >"$test_dir/prepare.out" 2>&1; then
  printf 'FAIL: nixos rotation prepare ignored unlock failure\n' >&2
  exit 1
fi
if compgen -G "$root_tmp/*" >/dev/null; then
  printf 'FAIL: nixos rotation prepare retained plaintext root after failure\n' >&2
  exit 1
fi

run_nixos rotation verify-next alpha
expected="${test_dir}/identity_rotation.py mark-next ${rotation_state} --repository . --derivation-index 1 --marker ${rotation_marker} alpha"
if [[ $(<"$rotation_args") != "$expected" ]]; then
  printf 'FAIL: nixos rotation verify-next dispatched unexpected arguments\n' >&2
  exit 1
fi

if REMOTE_TOKEN=wrong-token run_nixos rotation verify-next alpha >"$test_dir/verify-next.out" 2>&1; then
  printf 'FAIL: nixos rotation verify-next accepted a mismatched token\n' >&2
  exit 1
fi

run_nixos rotation recover
expected="${test_dir}/identity_artifacts.py recover --repository . --manifest ${rotation_state} --marker ${rotation_marker} --journal ${rotation_journal}"
if [[ $(<"$rotation_args") != "$expected" ]]; then
  printf 'FAIL: nixos rotation recover dispatched unexpected arguments\n' >&2
  exit 1
fi

touch "$finalization_journal"
run_nixos rotation recover
expected="${test_dir}/identity_finalization.py recover --repository . --journal ${finalization_journal} --backup ${finalization_backup} --runtime-current /tmp/id_age --runtime-previous /tmp/id_age_ --runtime-next /tmp/id_age_next"
if [[ $(<"$rotation_args") != "$expected" ]]; then
  printf 'FAIL: nixos rotation finalization recovery dispatched unexpected arguments\n' >&2
  exit 1
fi

# Cache commands must use Git-filtered flakes and stop if enumeration fails.
export CACHE_CALLS="$test_dir/cache.calls"
printf '#!%s\n' "$bash_bin" >"$mock_bin/nix"
cat >>"$mock_bin/nix" <<'EOF'
set -euo pipefail
printf 'nix %s\n' "$*" >>"$CACHE_CALLS"
case "$*" in
'eval --raw .#nixosConfigurations --apply '*)
  printf '%s\n' kit pow arm iso
  if [[ ${FAIL_HOST_ENUMERATION:-0} == "1" ]]; then
    printf 'test host enumeration failed\n' >&2
    exit 42
  fi
  ;;
'eval --raw .#nixosConfigurations.kit.config.system.build.toplevel.outPath' | \
'build --print-out-paths --no-link .#nixosConfigurations.kit.config.system.build.toplevel')
  printf '%s\n' /nix/store/test-kit
  ;;
'build --print-out-paths --no-link .#nixosConfigurations.pow.config.system.build.toplevel')
  printf '%s\n' /nix/store/test-pow
  ;;
'build --print-out-paths --no-link .#nixosConfigurations.arm.config.system.build.toplevel')
  printf '%s\n' /nix/store/test-arm
  ;;
'eval --raw .#nixosConfigurations.kit.config.nixpkgs.hostPlatform.system' | \
'eval --raw .#nixosConfigurations.pow.config.nixpkgs.hostPlatform.system')
  [[ ${FAIL_SYSTEM_EVALUATION:-0} != "1" ]]
  printf '%s\n' x86_64-linux
  ;;
'eval --raw .#nixosConfigurations.arm.config.nixpkgs.hostPlatform.system')
  printf '%s\n' aarch64-linux
  ;;
'print-dev-env --profile '*)
  [[ $4 == '.#devShells.x86_64-linux.default' || $4 == '.#devShells.aarch64-linux.default' ]]
  system=${4#'.#devShells.'}; system=${system%'.default'}
  ln -s "/nix/store/test-env-$system" "$3"
  [[ ${FAIL_DEVSHELL:-0} != "1" ]]
  ;;
*)
  printf 'FAIL: unexpected cache nix arguments: %s\n' "$*" >&2
  exit 96
  ;;
esac
EOF

printf '#!%s\n' "$bash_bin" >"$mock_bin/gum"
cat >>"$mock_bin/gum" <<'EOF'
set -euo pipefail
printf 'gum %s\n' "$*" >>"$CACHE_CALLS"
case "$1" in
style) printf '%s\n' "${*: -1}" ;;
choose) printf '%s\n' kit ;;
*) exit 97 ;;
esac
EOF

printf '#!%s\n' "$bash_bin" >"$mock_bin/attic"
cat >>"$mock_bin/attic" <<'EOF'
set -euo pipefail
printf 'attic %s\n' "$*" >>"$CACHE_CALLS"
if [[ $1 == "push" && $3 == /nix/store/test-env-* ]]; then
  [[ ${FAIL_DEVSHELL_PUSH:-0} != "1" ]]
fi
EOF
chmod +x "$mock_bin/attic"

run_nixos cache --dry-run kit >"$test_dir/cache.out" 2>&1
grep -q '\[dry-run\] kit -> /nix/store/test-kit' "$test_dir/cache.out"
if grep -q '^attic ' "$CACHE_CALLS"; then
  printf 'FAIL: nixos cache dry run reached Attic\n' >&2
  exit 1
fi
run_nixos cache --dry-run >"$test_dir/cache-interactive.out" 2>&1
grep -q '\[dry-run\] kit -> /nix/store/test-kit' "$test_dir/cache-interactive.out"
grep -q '\[dry-run\] devshell x86_64-linux' "$test_dir/cache.out"
if grep -Eq '^nix (build|print-dev-env)' "$CACHE_CALLS"; then
  printf 'FAIL: nixos cache dry run built an output\n' >&2
  exit 1
fi

cache_tmp="$test_dir/cache-tmp"
mkdir "$cache_tmp"
: >"$CACHE_CALLS"
TMPDIR="$cache_tmp" run_nixos cache --cache fleet kit pow arm >"$test_dir/cache-push.out" 2>&1
grep -qx 'attic cache info fleet' "$CACHE_CALLS"
for output in test-kit test-pow test-arm test-env-x86_64-linux test-env-aarch64-linux; do
  grep -qx "attic push fleet /nix/store/$output" "$CACHE_CALLS"
done
[[ $(grep -c '^nix print-dev-env ' "$CACHE_CALLS") == 2 ]]
[[ $(grep -c '^attic push fleet /nix/store/test-env-x86_64-linux$' "$CACHE_CALLS") == 1 ]]
[[ $(grep -c '^attic push fleet /nix/store/test-env-aarch64-linux$' "$CACHE_CALLS") == 1 ]]
if compgen -G "$cache_tmp/*" >/dev/null; then
  printf 'FAIL: nixos cache retained a temporary devshell profile\n' >&2
  exit 1
fi

for failure in FAIL_DEVSHELL FAIL_DEVSHELL_PUSH FAIL_SYSTEM_EVALUATION; do
  : >"$CACHE_CALLS"
  if env "$failure=1" TMPDIR="$cache_tmp" \
    IDENTITY_ROTATION_MARKER="$rotation_marker" PATH="$mock_bin:$PATH" \
    bash "$nixos_script" cache kit >"$test_dir/cache-shell-failure.out" 2>&1; then
    printf 'FAIL: nixos cache ignored %s\n' "$failure" >&2
    exit 1
  fi
  if [[ $failure == FAIL_DEVSHELL ]] && grep -q '^attic push main /nix/store/test-env-' "$CACHE_CALLS"; then
    printf 'FAIL: nixos cache pushed a failed devshell\n' >&2
    exit 1
  fi
  if [[ $failure == FAIL_SYSTEM_EVALUATION ]] && grep -Eq '^(attic |nix build|nix print-dev-env)' "$CACHE_CALLS"; then
    printf 'FAIL: nixos cache continued after system-evaluation failure\n' >&2
    exit 1
  fi
  if compgen -G "$cache_tmp/*" >/dev/null; then
    printf 'FAIL: nixos cache retained a temporary profile after %s\n' "$failure" >&2
    exit 1
  fi
done

for host in '' kit; do
  args=()
  [[ -z $host ]] || args=("$host")
  : >"$CACHE_CALLS"
  if FAIL_HOST_ENUMERATION=1 run_nixos cache "${args[@]}" >"$test_dir/cache-failure.out" 2>&1; then
    printf 'FAIL: nixos cache ignored host-enumeration failure\n' >&2
    exit 1
  fi
  grep -q 'Failed to list nixosConfigurations' "$test_dir/cache-failure.out"
  if grep -Eq '^(gum choose|attic |nix build)|Unknown nixosConfiguration host' "$CACHE_CALLS" "$test_dir/cache-failure.out"; then
    printf 'FAIL: nixos cache continued after host-enumeration failure\n' >&2
    exit 1
  fi
done
