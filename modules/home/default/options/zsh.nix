{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.zsh;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    home.packages = [pkgs.zsh-fzf-tab];
    programs.zsh = {
      autocd = true;
      # enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "emacs";

      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreDups = true;
        ignorePatterns = [];
        ignoreSpace = false;
        save = 10000;
        share = true;
        size = 10000;
      };

      shellAliases = {
        switch = "echo nixos-rebuild switch --flake /etc/nixos#$(hostname) && sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      };

      # oh-my-zsh = {
      #   enable = lib.mkDefault true;
      #   theme = "af-magic"; # "robbyrussell" "cypher"
      # };

      initContent = ''
        # Extract mp4 video from *.MP.jpg
        # https://linuxreviews.org/Google_Pixel_%22Motion_Photo%22
        extract () {
          extractposition=$(grep --binary --byte-offset --only-matching --text -P "\x00\x00\x00\x1C\x66\x74\x79\x70\x69\x73\x6f\x6d" $1 | sed 's/^\([0-9]*\).*/\1/')
          dd if="$1" skip=1 bs=$extractposition of="$(basename -s .jpg $1).mp4"
        }

        # Unless run with sudo, run "systemctl --user" and "journalctl --user" by default
        systemctl() { [ $EUID -eq 0 ] && command systemctl "$@" || command systemctl --user "$@"; }

        # journalctl keeps an explicit scope, and reads the system journal when
        # a -u unit is not a user unit (journalctl -u cliproxyapi just works)
        journalctl() {
          (( EUID == 0 )) && { command journalctl "$@"; return; }
          local arg take= unit
          local -a units
          for arg in "$@"; do
            if [[ -n $take ]]; then units+=("$arg"); take=; continue; fi
            case $arg in
              --system|--user|--machine*|--directory*|--file*|--root*|--image*|-[DM]*)
                command journalctl "$@"; return ;;
              --unit=*) units+=("''${arg#--unit=}") ;;
              --unit) take=1 ;;
              --*) ;;
              *) [[ $arg =~ '^-[aefklmNqrx]*u(.*)$' ]] && { [[ -n $match[1] ]] && units+=("$match[1]") || take=1; } ;;
            esac
          done
          for unit in "''${units[@]}"; do
            command systemctl --user cat -- "$unit" &>/dev/null || { command journalctl "$@"; return; }
          done
          command journalctl --user "$@"
        }

        # Fix tab completion (disabled because this makes # useless)
        # setopt EXTENDED_GLOB

        # MOTD: allow-list terminal contexts to avoid GDM/session handoff leakage.
        # Intended: SSH (SSH_CONNECTION/SSH_TTY), kitty (KITTY_WINDOW_ID or TERM=xterm-kitty),
        # or real Linux VT (TERM=linux with parent login/agetty).
        if [[ -t 1 && ( -n "$SSH_CONNECTION" || -n "$SSH_TTY" || -n "$KITTY_WINDOW_ID" || "$TERM" = xterm-kitty || ( "$TERM" = linux && $(ps -o comm= -p $PPID 2>/dev/null) =~ ^(login|agetty)$ ) ) ]]; then
          cat /var/lib/rust-motd/motd
        fi
      '';

      autosuggestion.enable = true;

      # Custom location for history and more
      dotDir = "${config.xdg.configHome}/zsh";
      history.path = "${config.xdg.dataHome}/zsh/zsh_history";
    };

    # Persist zsh history
    persist.storage.directories = [".local/share/zsh"];
  };
}
