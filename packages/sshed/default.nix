{
  pkgs,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) readFile;
  inherit (pkgs) git gnugrep gum inetutils iptables netcat age;
  inherit (perSystem.self) derive ipaddr;
in
  perSystem.self.mkScript {
    name = "sshed";
    path = [derive git gnugrep gum inetutils ipaddr iptables netcat age];

    # Derivation path for key
    env.derivation_path = "bip85-hex32-index${toString flake.derivationIndex}";

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

        # List subdirectories for given directory
        dirs() { find "$1" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; }

        # First arg is command: generate|receive|send
        command="''${1-}"

        # Second arg is HOST or REBOOT
        host="''${2-}"
        reboot="''${2-}"

        # Third arg is IP
        ip="''${3-}"

        case "$command" in
          generate|gen|g)
            ${readFile ./generate.sh}
            ;;
          receive|r)
            ${readFile ./receive.sh}
            ;;
          send|s)
            ${readFile ./send.sh}
            ;;
          verify|v)
            ${readFile ./verify.sh}
            ;;
          help | *)
            echo "Usage: sshed COMMAND"
            echo
            echo "  generate"
            echo "  receive"
            echo "  send [HOST] [IP]"
            echo "  verify"
            echo "  help"
            ;;
        esac
      '';
  }
