#!/usr/bin/env bash
set -euo pipefail

derive_bin="${DERIVE_BIN:-derive}"
root="000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
root_upper="${root^^}"
base64_root="AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8="
raw_32="abcdefghijklmnopqrstuvwxyzABCDEF"

derive_hex() {
  local input="$1"
  shift
  printf '%s' "$input" | "$derive_bin" hex "$@"
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local description="$3"
  if [[ $actual != "$expected" ]]; then
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$description" "$expected" "$actual" >&2
    return 1
  fi
}

assert_equal "$root" "$(derive_hex "$root")" "lowercase hex remains unchanged"
assert_equal "$root" "$(derive_hex "$root_upper")" "uppercase hex is canonicalized"
assert_equal \
  "cac50d5a0cd712abca377a4163ba871e1c433b4a8be3113e9e4dcd2cbf9dbec0" \
  "$(derive_hex "$root" host)" \
  "lowercase salted v1 vector remains unchanged"
assert_equal \
  "$(derive_hex "$root" host)" \
  "$(derive_hex "$root_upper" host)" \
  "hex casing does not change salted derivation"
assert_equal "$root" "$(derive_hex "$base64_root")" "base64 decoding remains unchanged"
assert_equal \
  "54be0cce7bfdf169c66f09551325d08b4ddb64040715db501a0c90e6dc4abb4e" \
  "$(derive_hex "$base64_root" host)" \
  "salted base64 text derivation remains unchanged"
assert_equal \
  "6162636465666768696a6b6c6d6e6f707172737475767778797a414243444546" \
  "$(derive_hex "$raw_32")" \
  "32-byte raw input remains unchanged"
assert_equal \
  "1d9b77c0ba81c3da59e8883489ff42ab8c3f168e708900b831b1315816e70aac" \
  "$(derive_hex "$raw_32" host)" \
  "salted raw text derivation remains unchanged"
