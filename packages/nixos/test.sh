#!/usr/bin/env bash
set -euo pipefail

nixos_script="${NIXOS_SCRIPT:?NIXOS_SCRIPT is required}"
bash_bin="${BASH_BIN:?BASH_BIN is required}"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

mock_bin="$test_dir/bin"
repo="$test_dir/repo"
mkdir -p "$mock_bin" "$repo/secrets/rotation"
printf '{"phase": "prepare", "nextIndex": 0}\n' >"$repo/secrets/rotation/state.json"

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

printf '#!%s\n' "$bash_bin" >"$mock_bin/agenix"
cat >>"$mock_bin/agenix" <<'EOF'
printf 'FAIL: guarded command reached agenix %s\n' "$1" >&2
exit 98
EOF
chmod +x "$mock_bin/agenix"

run_nixos() {
  (
    cd "$repo"
    env -u PRJ_ROOT derivation_index=1 PATH="$mock_bin:$PATH" bash "$nixos_script" "$@"
  )
}

# Identity rewrites stop before doing any work during a rotation.
if run_nixos generate >"$test_dir/generate.out" 2>&1; then
  printf 'FAIL: nixos generate ran while identity rotation was active\n' >&2
  exit 1
fi
if grep -q 'reached' "$test_dir/generate.out"; then
  printf 'FAIL: nixos generate did work before refusing\n' >&2
  exit 1
fi

if run_nixos add host >"$test_dir/add.out" 2>&1; then
  printf 'FAIL: nixos add ran while identity rotation was active\n' >&2
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
chmod +x "$mock_bin/nix"

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
    PATH="$mock_bin:$PATH" bash "$nixos_script" cache kit >"$test_dir/cache-shell-failure.out" 2>&1; then
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
