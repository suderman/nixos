#!/usr/bin/env bash
set -euo pipefail

agenix_script="${AGENIX_SCRIPT:?AGENIX_SCRIPT is required}"
bash_bin="${BASH_BIN:?BASH_BIN is required}"
real_mv="${REAL_MV:?REAL_MV is required}"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

mock_bin="$test_dir/bin"
secrets_dir="$test_dir/secrets"
runtime_dir="$test_dir/runtime"
mkdir -p "$mock_bin" "$secrets_dir" "$runtime_dir"

printf '#!%s\n' "$bash_bin" >"$mock_bin/gum"
cat >>"$mock_bin/gum" <<'EOF'
set -euo pipefail
case "$1" in
confirm)
  exit 0
  ;;
choose)
  printf '%s\n' "Enter manually"
  ;;
input)
  printf '%s\n' "${TEST_HEX:?TEST_HEX is required}"
  ;;
style)
  printf '%s\n' "${*: -1}"
  ;;
esac
EOF

printf '#!%s\n' "$bash_bin" >"$mock_bin/age"
cat >>"$mock_bin/age" <<'EOF'
set -euo pipefail
if [[ " $* " == *" -e "* && " $* " == *" -p "* ]]; then
  printf '%s\n' "mock-passphrase-encryption"
  cat
elif [[ " $* " == *" -e "* && " $* " == *" -R "* ]]; then
  printf '%s\n' "mock-recipient-encryption"
  cat
elif [[ " $* " == *" -d "* ]]; then
  read -r header
  case "$header" in
  mock-passphrase-encryption | mock-recipient-encryption)
    cat
    ;;
  *)
    printf '%s\n' "$header"
    cat
    ;;
  esac
else
  exit 2
fi
EOF

printf '#!%s\n' "$bash_bin" >"$mock_bin/git"
cat >>"$mock_bin/git" <<'EOF'
exit 0
EOF

chmod +x "$mock_bin/age" "$mock_bin/git" "$mock_bin/gum"

root="000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
root_upper="${root^^}"
other_root="100102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
TEST_HEX="$root"

run_agenix() {
  env \
    AGENIX_RUNTIME_DIR="$runtime_dir" \
    AGENIX_SECRETS_DIR="$secrets_dir" \
    TEST_HEX="$TEST_HEX" \
    PATH="$mock_bin:$PATH" \
    bash "$agenix_script" "$@"
}

artifact_hashes() {
  sha256sum "$secrets_dir/id_age.age" "$secrets_dir/id_age.pub" "$secrets_dir/hex.age"
}

# Fresh bootstrap accepts uppercase input but persists the canonical lowercase root.
TEST_HEX="$root_upper" run_agenix import >"$test_dir/fresh.out"
[[ -s $secrets_dir/id_age.age ]]
[[ -s $secrets_dir/id_age.pub ]]
[[ -s $secrets_dir/hex.age ]]
[[ $(run_agenix hex) == "$root" ]]

# Canonical validation reports status without disclosing the root.
run_agenix hex --check >"$test_dir/check.out" 2>&1
if grep -Fq "$root" "$test_dir/check.out"; then
  printf 'FAIL: agenix hex --check disclosed the root\n' >&2
  exit 1
fi

cp "$secrets_dir/hex.age" "$test_dir/canonical-hex.age"
printf '%s\n' "mock-recipient-encryption" "$root_upper" >"$secrets_dir/hex.age"
if run_agenix hex --check >"$test_dir/noncanonical-check.out" 2>&1; then
  printf 'FAIL: agenix hex --check accepted an uppercase root\n' >&2
  exit 1
fi
if grep -Fq "$root_upper" "$test_dir/noncanonical-check.out"; then
  printf 'FAIL: failed agenix hex --check disclosed the root\n' >&2
  exit 1
fi
cp "$test_dir/canonical-hex.age" "$secrets_dir/hex.age"

# Recovery with the same root replaces damaged encrypted artifacts.
printf '%s\n' "damaged" >"$secrets_dir/id_age.age"
printf '%s\n' "mock-recipient-encryption" "damaged" >"$secrets_dir/hex.age"
TEST_HEX="$root" run_agenix import >"$test_dir/recovery.out"
[[ $(run_agenix hex) == "$root" ]]

# A different root is refused before any artifact is changed.
before_refusal="$(artifact_hashes)"
if TEST_HEX="$other_root" run_agenix import >"$test_dir/refusal.out" 2>&1; then
  printf 'FAIL: import accepted a different master root\n' >&2
  exit 1
fi
[[ $(artifact_hashes) == "$before_refusal" ]]

# A failure during the commit restores every prior artifact.
fail_bin="$test_dir/fail-bin"
mkdir -p "$fail_bin"
printf '#!%s\n' "$bash_bin" >"$fail_bin/mv"
cat >>"$fail_bin/mv" <<'EOF'
set -euo pipefail
count=0
[[ ! -f $TEST_MV_COUNT ]] || count="$(<"$TEST_MV_COUNT")"
count=$((count + 1))
printf '%s\n' "$count" >"$TEST_MV_COUNT"
if [[ $count -eq 2 ]]; then
  exit 75
fi
exec "$REAL_MV" "$@"
EOF
chmod +x "$fail_bin/mv"

before_interruption="$(artifact_hashes)"
if env \
  AGENIX_RUNTIME_DIR="$runtime_dir" \
  AGENIX_SECRETS_DIR="$secrets_dir" \
  TEST_HEX="$root" \
  TEST_MV_COUNT="$test_dir/mv-count" \
  REAL_MV="$real_mv" \
  PATH="$fail_bin:$mock_bin:$PATH" \
  bash "$agenix_script" import >"$test_dir/interruption.out" 2>&1; then
  printf 'FAIL: interrupted import unexpectedly succeeded\n' >&2
  exit 1
fi
[[ $(artifact_hashes) == "$before_interruption" ]]
