{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    autocd = true;
    # enableAutosuggestions = true;
    enableCompletion = true;
    defaultKeymap = "viins"; # emacs, vicmd, or viins

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

    oh-my-zsh = {
      enable = lib.mkDefault true;
      theme = "af-magic"; # "robbyrussell" "cypher"
    };

    initContent = ''
      # Extract mp4 video from *.MP.jpg
      # https://linuxreviews.org/Google_Pixel_%22Motion_Photo%22
      extract () {
        extractposition=$(grep --binary --byte-offset --only-matching --text -P "\x00\x00\x00\x1C\x66\x74\x79\x70\x69\x73\x6f\x6d" $1 | sed 's/^\([0-9]*\).*/\1/')
        dd if="$1" skip=1 bs=$extractposition of="$(basename -s .jpg $1).mp4"
      }

      # Unless run with sudo, run "systemctl --user" and "journalclt --user" by default
      systemctl() { [ $EUID -eq 0 ] && command systemctl "$@" || command systemctl --user "$@"; }
      journalctl() { [ $EUID -eq 0 ] && command journalctl "$@" || command journalctl --user "$@"; }

      # Fix tab completion (disabled because this makes # useless)
      # setopt EXTENDED_GLOB

      # message of the day
      [[ -e /var/lib/rust-motd/motd ]] && cat /var/lib/rust-motd/motd
    '';

    autosuggestion.enable = true;

    # Custom location for history and more
    dotDir = ".config/zsh";
    history.path = "${config.xdg.dataHome}/zsh/zsh_history";
  };

  # Persist zsh history
  impermanence.persist.directories = [".local/share/zsh"];

  home.packages = [pkgs.zsh-fzf-tab];
}
