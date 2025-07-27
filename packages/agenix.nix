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
  ];

  # Use same name as existing agenix command we're extending
  name = "agenix";

  text =
    # bash
    ''
      #! /usr/bin/env bash
      set -euo pipefail
      source ${flake.lib.bash}

      # Import 32 byte hex from QR saved as hex.age and generate identity id.age
      import() {
        cd "$PRJ_ROOT" || exit

        # Confirm derivation path
        pause "Derive Seeds (BIP-85) > 32-bytes hex > Index Number $DERIVATION_INDEX"

        if [[ -f id.age ]]; then
          [[ ! -s id.age ]] &&
            rm -f id.age ||
            error "./id.age already exists"
        fi

        # Attempt to read QR code master key (hex32)
        hex="$(qr)"
        [[ ! -z "$hex" ]] &&
          info "QR code scanned!" ||
          error "Failed to read QR code"

        # Write a password-protected copy of the age identity
        echo "$hex" |
          derive age |
          age -ep >id.age
        info "Private age identity written: ./id.age"

        # Write the age identity's public key
        echo "$hex" |
          derive age |
          derive public >id.pub
        git add id.pub 2>/dev/null || true
        info "Public age identity written: ./id.pub"

        # Write the 32-byte hex (protected by age identity)
        echo "$hex" |
          age -eR id.pub >hex.age
        git add hex.age 2>/dev/null || true
        info "Private 32-byte hex written: ./hex.age"

        # Unlock the id right away
        echo "$hex" | derive age | unlock-id
      }

      # Decrypt id.age to /tmp/id_age using passhrase
      unlock() {
        cd "$PRJ_ROOT" || exit

        id="$(input)"
        if [[ -z "$id" ]]; then
          [[ ! -f id.age ]] && error "./id.age missing"
          id="$(cat id.age | age -d)"
          [[ -z "$id" ]] && error "Failed to unlock age identity"
        fi

        [[ -f /tmp/id_age ]] && mv /tmp/id_age /tmp/id_age_
        touch /tmp/id_age_
        echo "$id" >/tmp/id_age
        chmod 600 /tmp/id_age /tmp/id_age_

        info "Age identity unlocked"
      }

      # Delete decrypted /tmp/id_age
      lock() {
        cd "$PRJ_ROOT" || exit
        rm -f /tmp/id_age /tmp/id_age_
        info "Age identity locked"
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
