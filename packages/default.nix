{
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) readFile;
  inherit (pkgs) git gnugrep inetutils iptables netcat age;
  inherit (perSystem.self) derive ipaddr;
in
  perSystem.self.mkScript {
    path = with pkgs; [
      derive
      git
      gnugrep
      inetutils
      ipaddr
      iptables
      netcat
      age
      gum
      alejandra
    ];

    name = "nixos";

    text =
      # bash
      ''
        #! /usr/bin/env bash
        set -euo pipefail

        # Pretty output
        gum_warn() { gum style --foreground=196 "✖ Error: $*" && return 1; }
        gum_info() { gum style --foreground=29 "➜ $*"; }
        gum_head() { gum style --foreground=99 "$*"; }
        gum_show() { gum style --foreground=177 "    $*"; }

        add() {
          add_type=$(gum choose --header="Add to this flake:" "user" "host")
          "add_''${add_type}"
        }

        add_user() {
          gum_head "Add a user to this flake:"
          local username="$(gum input --placeholder "username")"

          # Ensure a username was provided
          [[ -z "$username" ]] && gum_warn "Missing username"
          local user="users/''${username}"

          # Ensure it doesn't already exist
          if [[ -e "$user" ]]; then
            gum_info "User configuration exists:"
            gum_show "./$user"
          else

            # Create host directory
            mkdir -p "$user"

            # Create an encrypted password.age file (value is x)
            echo "x" |
              age -e -r "$(derive public </tmp/id_age)" \
                >"$user"/password.age

            # Create a basic default.nix in this directory
            {
              echo '{'
              echo '  uid = null;'
              echo '  description = "User";'
              echo '  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];'
              echo '}'
            } | alejandra -q >"$user/default.nix"

            # Stage in git
            git add "$user" 2>/dev/null || true
            gum_info "User configuration staged: ./$user"
          fi

          # Generate missing files
          generate
        }

        add_host() {
          gum_head "Add a host to this flake:"
          local hostname="$(gum input --placeholder "hostname")"

          # Ensure a hostname was provided
          [[ -z "$hostname" ]] && gum_warn "Missing hostname"
          local host="hosts/''${hostname}"

          # Ensure it doesn't already exist
          if [[ -e "$host" ]]; then
            gum_info "Host configuration exists:"
            gum_show "./$host"
          else

            # Create host directory
            mkdir -p "$host"/users

            # Add users for home-manager configuration
            for user in $(find users -mindepth 1 -maxdepth 1 -type d -printf '%f\n'); do
              local expr="({ isSystemUser = false; } // (import ./users/$user)).isSystemUser"
              if [[ "$(nix eval --impure --expr "$expr")" == "false" ]]; then
                {
                  echo '{ flake, ... }: {'
                  echo '  imports = [ flake.homeModules.common ];'
                  echo '}'
                } | alejandra -q >"$host/users/$user.nix"
              fi
            done

            # Create a basic configuration.nix in this directory
            {
              echo '{ flake, ... }: {'
              echo '  imports = [ flake.nixosModules.common ];'
              echo '}'
            } | alejandra -q >"$host/configuration.nix"

            # Stage in git
            git add "$host" 2>/dev/null || true
            gum_info "Host configuration staged: ./$host"
          fi

          # Generate missing files
          generate
        }

        generate() {

          # Generate missing SSH keys for hosts and users
          gum_info "Generating SSH keys..."
          sshed generate

          # Ensure Certificate Authority exists
          if [[ -s zones/ca.crt && -s zones/ca.age ]]; then
            gum_info "Certificate Authority exists..."
            gum_show "./zones/ca.crt"
            gum_show "./zones/ca.age"

          # If it doesn't, generate and add to git
          else
            gum_info "Generating Certificate Authority..."

            # Generate CA key and save to variable
            ca_key=$(mktemp)
            openssl genrsa -out "$ca_key" 4096

            # Generate CA certificate expiring in 70 years
            openssl req -new -x509 -nodes \
              -extensions v3_ca \
              -days 25568 \
              -subj "/CN=Suderman CA" \
              -key "$ca_key" \
              -out zones/ca.crt

            git add zones/ca.crt 2>/dev/null || true
            gum_show "./zones/ca.crt"

            # Encrypt CA key with age identity
            age -e -r "$(derive public </tmp/id_age)" <"$ca_key" \
              >zones/ca.age
            shred -u "$ca_key"

            git add zones/ca.age 2>/dev/null || true
            gum_show "./zones/ca.age"

          fi

          # Ensure secrets are rekeyed for all hosts
          gum_info "Rekeying secrets..."
          agenix rekey -a
        }

        # Command dispatch
        cmd="''${1:-}"
        case "$cmd" in
          add|generate|repl|deploy)
            "$cmd"
            exit 0
            ;;
          ""|--help|-h|help)
            echo "Usage: nix run . COMMAND"
            echo
            echo "  add"
            echo "  generate"
            echo "  help"
            ;;
        esac
      '';
  }
