# programs.zsh.enable = true;
{ config, lib, pkgs, ... }:

let 
  cfg = config.programs.zsh;

in {

  config = lib.mkIf cfg.enable {

    programs.zsh = {
      autocd = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      defaultKeymap = "viins"; # emacs, vicmd, or viins

      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreDups = true;
        ignorePatterns = [ ];
        ignoreSpace = false;
        save = 10000;
        share = true;
        size = 10000;
      };

      shellAliases = {
        switch = "echo nixos-rebuild switch --flake /etc/nixos#$(hostname) && sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      };

      oh-my-zsh = {
        enable = true;
        # theme = "robbyrussell";
        # theme = "cypher";
        theme = "af-magic";
      };

      initExtra = ''
        # Extract mp4 video from *.MP.jpg 
        # https://linuxreviews.org/Google_Pixel_%22Motion_Photo%22
        extract () {
          extractposition=$(grep --binary --byte-offset --only-matching --text -P "\x00\x00\x00\x1C\x66\x74\x79\x70\x69\x73\x6f\x6d" $1 | sed 's/^\([0-9]*\).*/\1/')
          dd if="$1" skip=1 bs=$extractposition of="$(basename -s .jpg $1).mp4"
        }

        # Unless run with sudo, run "systemctl --user" and "journalclt --user" by default
        systemctl() { [ $EUID -eq 0 ] && command systemctl "$@" || command systemctl --user "$@"; }
        journalctl() { [ $EUID -eq 0 ] && command journalctl "$@" || command journalctl --user "$@"; }

        ## zsh-fzf-tab
        #. ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        # message of the day
        [[ -e /var/lib/rust-motd/motd ]] && cat /var/lib/rust-motd/motd
      '';

    };

    home.packages = [ pkgs.zsh-fzf-tab ];

  };

}
