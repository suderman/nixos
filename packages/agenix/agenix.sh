#! /usr/bin/env bash
set -euo pipefail

# Pretty output
gum_warn() { gum style --foreground=196 "✖ Error: $*" && exit 1; }
gum_info() { gum style --foreground=29 "➜ $*"; }
gum_show() { gum style --foreground=177 "    $*"; }

# If PRJ_ROOT is set, change to that directory
[[ -n "$PRJ_ROOT" ]] && cd "$PRJ_ROOT"

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
    agenix_unlock
    exit 0
    ;;
  lock | l)
    agenix_lock
    exit 0
    ;;
  "" | --help | -h | help)
    agenix --help "$@" || true
    agenix_help
    exit 0
    ;;
  *)
    agenix "$@"
    ;;
  esac

}

# Display extended commands with agenix help
agenix_help() {
  cat <<EOF

EXTENDED COMMANDS:
  import                  Import a QR-derived age identity to id.age
  unlock                  Unlock id.age to /tmp/id_age
  lock                    Remove temporary age identity from /tmp/id_age
EOF
}

# Import 32 byte hex from QR saved as hex.age and generate identity id.age
agenix_import() {

  # Confirm derivation path
  gum confirm "Derive Seeds (BIP-85) > 32-bytes hex > Index Number ${derivation_index-}"

  # Delete id.age if it exists but is empty
  [[ ! -s id.age ]] &&
    rm -f id.age

  # Stop if there is already an id.age that exists
  [[ -f id.age ]] &&
    gum_warn "./id.age already exists"

  # Attempt to read QR code master key (hex32)
  hex="$(qr)"
  if [[ -z "$hex" ]]; then
    gum_warn "Failed to read QR code"
  else
    gum_info "QR code scanned!"
  fi

  # Write a password-protected copy of the age identity
  derive age <<<"$hex" | age -ep >id.age
  gum_info "Private age identity written:"
  gum_show "./id.age"

  # Write the age identity's public key
  derive age <<<"$hex" | derive public >id.pub
  git add id.pub 2>/dev/null || true
  gum_info "Public age identity written:"
  gum_show "./id.pub"

  # Write the 32-byte hex (protected by age identity)
  age -eR id.pub <<<"$hex" >hex.age
  git add hex.age 2>/dev/null || true
  gum_info "Private 32-byte hex written:"
  gum_show "./hex.age"

  # Unlock the id right away
  derive age <<<"$hex" | unlock
}

# Decrypt id.age to /tmp/id_age using passhrase
agenix_unlock() {

  id="$([ -t 0 ] || cat)"
  if [[ -z "$id" ]]; then
    [[ ! -f id.age ]] && gum_warn "./id.age missing"
    id="$(age -d <id.age 2>/dev/null || true)"
    [[ -z "$id" ]] && gum_warn "Incorrect passphrase"
  fi
  [[ -f /tmp/id_age ]] && mv /tmp/id_age /tmp/id_age_
  touch /tmp/id_age_
  echo "$id" >/tmp/id_age
  chmod 600 /tmp/id_age /tmp/id_age_

  gum style \
    --border="rounded" \
    --border-foreground="29" \
    --foreground="82" \
    --padding="0 1" \
    "🔓 Age identity unlocked"
}

# Delete decrypted /tmp/id_age
agenux_lock() {
  rm -f /tmp/id_age /tmp/id_age_
  gum style \
    --border="rounded" \
    --border-foreground="124" \
    --foreground="196" \
    --padding="0 1" \
    "🔒 Age identity locked"
}

main "${@-}"
