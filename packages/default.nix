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

        gum_error() {
          gum style --foreground=196 "✖ Error: $*"
          return 1
        }

        gum_info() {
          gum style --foreground=29 "➜ $*"
          return 0
        }

        gum_header() {
          gum style --foreground=99 "$*"
          return 0
        }


        add() {
          add_type=$(gum choose --header="Add to this flake:" "user" "host")
          "add_''${add_type}"
        }

        add_user() {
          gum_header "Add a user to this flake:"
          local username="$(gum input --placeholder "username")"

          # Ensure a username was provided
          [[ -z "$username" ]] && gum_error "Missing username"
          local user="users/''${username}"

          # Ensure it doesn't already exist
          if [[ -e "$user" ]]; then
            gum_info "User configuration exists: ./$user"
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
        }

        add_host() {
          gum_header "Add a host to this flake:"
          local hostname="$(gum input --placeholder "hostname")"

          # Ensure a hostname was provided
          [[ -z "$hostname" ]] && gum_error "Missing hostname"
          local host="hosts/''${hostname}"

          # Ensure it doesn't already exist
          if [[ -e "$host" ]]; then
            gum_info "Host configuration exists: ./$host"
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
