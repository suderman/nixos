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

      # If PRJ_ROOT is set, change to that directory
      [[ -n "$PRJ_ROOT" ]] && cd "$PRJ_ROOT"

      # Command dispatch
      cmd="''${1:-}"
      case "$cmd" in
        import|unlock|lock)
          "$cmd"
          exit 0
          ;;
        ""|--help|-h|help)
          echo help info
          exit 0
          ;;
      esac
    '';
}
