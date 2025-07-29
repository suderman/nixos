{
  pkgs,
  perSystem,
  flake,
  ...
}:
perSystem.self.mkScript {
  path = [
    perSystem.agenix-rekey.default # agenix command to extend
    perSystem.self.derive
    perSystem.self.qr
    pkgs.age
    pkgs.git
    pkgs.gum
  ];

  # Use same name as existing agenix command we're extending
  name = "agenix";

  text =
    # bash
    ''
      #! /usr/bin/env bash
      set -euo pipefail

      gum_error() {
        gum style --foreground=196 "✖ Error: $*"
        return 1
      }

      gum_info() {
        gum style --foreground=29 "➜ $*"
        return 0
      }

      # If PRJ_ROOT is set, change to that directory
      [[ -n "$PRJ_ROOT" ]] && cd "$PRJ_ROOT"

      # Import 32 byte hex from QR saved as hex.age and generate identity id.age
      import() {

        # Confirm derivation path
        gum confirm "Derive Seeds (BIP-85) > 32-bytes hex > Index Number ${toString flake.derivationIndex}";

        # Delete id.age if it exists but is empty
        [[ ! -s id.age ]] &&
          rm -f id.age

        # Stop if there is already an id.age that exists
        [[ -f id.age ]] &&
          gum_error "./id.age already exists"

        # Attempt to read QR code master key (hex32)
        hex="$(qr)"
        if [[ -z "$hex" ]]; then
          gum_error "Failed to read QR code"
        else
          gum_info "QR code scanned!"
        fi

        # Write a password-protected copy of the age identity
        derive age <<<"$hex" | age -ep >id.age
        gum_info "Private age identity written: ./id.age"

        # Write the age identity's public key
        derive age <<<"$hex" | derive public >id.pub
        git add id.pub 2>/dev/null || true
        gum_info "Public age identity written: ./id.pub"

        # Write the 32-byte hex (protected by age identity)
        age -eR id.pub <<<"$hex" >hex.age
        git add hex.age 2>/dev/null || true
        gum_info "Private 32-byte hex written: ./hex.age"

        # Unlock the id right away
        derive age <<<"$hex" | unlock
      }

      # Decrypt id.age to /tmp/id_age using passhrase
      unlock() {

        id="$([ -t 0 ] || cat)"
        if [[ -z "$id" ]]; then
          [[ ! -f id.age ]] && gum_error "./id.age missing"
          id="$(age -d <id.age 2>/dev/null || true)"
          [[ -z "$id" ]] && gum_error "Incorrect passphrase"
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
      lock() {
        rm -f /tmp/id_age /tmp/id_age_
        gum style \
          --border="rounded" \
          --border-foreground="124" \
          --foreground="196" \
          --padding="0 1" \
          "🔒 Age identity locked"
      }

      # Display extended commands with agenix help
      show_extended_help() {
        cat <<EOF

      EXTENDED COMMANDS:
        import                  Import a QR-derived age identity to id.age
        unlock                  Unlock id.age to /tmp/id_age
        lock                    Remove temporary age identity (/tmp/id_age)
      EOF
      }

      # Command dispatch
      cmd="''${1:-}"
      case "$cmd" in
        import|unlock|lock)
          "$cmd"
          exit 0
          ;;
        ""|--help|-h|help)
          agenix --help "$@" || true
          show_extended_help
          exit 0
          ;;
        *)
          agenix "$@"
          ;;
      esac
    '';
}
