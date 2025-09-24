#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_exit() { gum style --foreground=196 "✖ $*" && return 1; }
gum_warn() { gum style --foreground=124 "✖ $*"; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_head() { gum style --foreground=99 "$*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# If PRJ_ROOT is set, change to that directory
[[ -n "${PRJ_ROOT-}" ]] && cd "$PRJ_ROOT"

# ---------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------
main() {

  case "${1:-}" in
  import | i)
    agenix_import
    exit 0
    ;;
  unlock | u)
    agenix_unlock "${2:-}"
    exit 0
    ;;
  lock | l)
    agenix_lock
    exit 0
    ;;
  hex | h)
    agenix_hex
    exit 0
    ;;
  verify | v)
    agenix_verify "${2:-}"
    exit 0
    ;;
  "" | --help | -h | help)
    agenix --help "$@" || true
    agenix_help
    exit 0
    ;;
  *)
    agenix_unlock quiet
    agenix "$@"
    ;;
  esac

}

# Display extended commands with agenix help
agenix_help() {
  cat <<EOF

EXTENDED COMMANDS:
  import                  Import a QR-derived age identity to secrets/id_age.age
  unlock                  Unlock secrets/id_age.age to /tmp/id_age
  lock                    Remove temporary age identity from /tmp/id_age
  hex                     Output decrypted secrets/hex.age using age identity
  verify [DIR]            Verify match in directory's id_age & id_age.pub
EOF
}

# Import 32 byte hex from QR saved as secrets/hex.age and generate identity secrets/id_age.age
agenix_import() {

  # Confirm derivation path
  local path="Derive Seeds (BIP-85) > 32-bytes hex > Index Number ${derivation_index-}"
  gum confirm "$path"
  gum_head "$path"

  # Master key (32-byte hex)
  local hex=""

  # If GUI detected, offer QR scanning
  if [[ -n "${DISPLAY-}" || -n "${WAYLAND_DISPLAY-}" ]]; then
    if [[ "$(gum choose "Scan QR code" "Enter manually")" == "Scan QR code" ]]; then
      hex="$(qr || true)"
    fi
  fi

  # If hex not entered via QR, allow manual input
  if [[ -z "$hex" ]]; then
    hex="$(gum input --placeholder "Enter 32-byte hex" | xargs)"
  fi

  # Ensure valid 32-byte hex code receieved
  if [[ $hex =~ ^[0-9a-fA-F]{64}$ ]]; then
    gum_info "32-byte hex code validated"
  else
    gum_exit "Failed to receive valid hex code"
  fi

  # Delete id_age.age if it exists but is empty
  [[ ! -s secrets/id_age.age ]] &&
    rm -f secrets/id_age.age

  # Confirm to overwrite existing secrets/id_age.age
  [[ -f secerts/id_age.age ]] &&
    gum confirm "./secrets/id_age.age already exists. Overwrite?"

  # Write a password-protected copy of the age identity
  derive age <<<"$hex" | age -e -p >secrets/id_age.age
  gum_info "Private age identity written:"
  gum_show "./secrets/id_age.age"

  # Write the age identity's public key
  derive age <<<"$hex" | derive public >secrets/id_age.pub
  git add secrets/id_age.pub 2>/dev/null || true
  gum_info "Public age identity written:"
  gum_show "./secrets/id_age.pub"

  # Write the 32-byte hex (protected by age identity)
  age -e -R secrets/id_age.pub <<<"$hex" >secrets/hex.age
  git add secrets/hex.age 2>/dev/null || true
  gum_info "Private 32-byte hex written:"
  gum_show "./secrets/hex.age"

  # Unlock the id right away
  derive age <<<"$hex" | agenix_unlock
}

# Decrypt secrets/id_age.age to /tmp/id_age using passhrase
agenix_unlock() {

  # If quiet and the decrypted age identity already exists, stop here
  if [[ "${1:-}" == "quiet" ]]; then
    [[ -f /tmp/id_age ]] && return 0
  fi

  # Optionally accept an age identity through standard input
  id="$([ -t 0 ] || cat)"

  # Attempt to decrypt age identity using passphrse
  if [[ -z "$id" ]]; then
    [[ ! -f secrets/id_age.age ]] && gum_exit "./secrets/id_age.age missing"
    id="$(age -d <secrets/id_age.age 2>/dev/null || true)"
    [[ -z "$id" ]] && gum_exit "Incorrect passphrase"
  fi

  # Shift any existing phrase to backup
  [[ -f /tmp/id_age ]] && mv /tmp/id_age /tmp/id_age_
  touch /tmp/id_age_

  # Write decrypted age identity to tmp directory
  echo "$id" >/tmp/id_age
  chmod 600 /tmp/id_age /tmp/id_age_

  # Notify user unless quiet
  if [[ "${1:-}" != "quiet" ]]; then
    gum style \
      --border="rounded" \
      --border-foreground="29" \
      --foreground="82" \
      --padding="0 1" \
      "🔓 Age identity unlocked"
  fi

}

# Delete decrypted /tmp/id_age
agenix_lock() {
  rm -f /tmp/id_age /tmp/id_age_
  gum style \
    --border="rounded" \
    --border-foreground="124" \
    --foreground="196" \
    --padding="0 1" \
    "🔒 Age identity locked"
}

# Output decrypted secrets/hex.age (32-byte hex)
agenix_hex() {
  [[ ! -f secrets/hex.age ]] && gum_exit "./secrets/hex.age missing"
  agenix_unlock quiet
  age -d -i /tmp/id_age <secrets/hex.age
}

# Check if directory with id_age and id_age.pub are valid match
agenix_verify() {

  local dir="${1:-$(pwd)}"

  local private_id_file="$dir/id_age"
  local public_id_file="$dir/id_age.pub"

  # Ensure private key exists
  [[ -f "$private_id_file" ]] ||
    gum_exit "[agenix] $private_id_file missing"

  # Ensure public key exists
  [[ -f "$public_id_file" ]] ||
    gum_exit "[agenix] $public_id_file missing"

  # Extract public id from current file
  current_public_id="$(xargs <"$public_id_file")"

  # Derive expected public id from current private id file (should match above)
  derived_public_id="$(derive public <"$private_id_file" | xargs)"

  # Ensure key pair actually matches
  if [[ "$current_public_id" == "$derived_public_id" ]]; then
    gum_info "[agenix] $private_id_file valid match"
  else
    gum_warn "[agenix] $private_id_file invalid match"
    return 1
  fi

}

main "${@-}"
