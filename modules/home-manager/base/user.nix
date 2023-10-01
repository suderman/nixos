{ config, lib, pkgs, base, ... }:

let

  cfg = config.modules.base;
  inherit (base) user;
  inherit (lib) mkIf;

in {

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------
  config = mkIf cfg.enable {

    home.username = user;
    home.homeDirectory = "/${if (pkgs.stdenv.isLinux) then "home" else "Users"}/${user}";

    # Add support for ~/.local/bin
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Aliases 
    home.shellAliases = with pkgs; rec {
      cp = "cp -i";
      rm = "rm -I";
      df = "df -h";
      # diff = "diff --color=auto";
      du = "du -ch --summarize";
      fst = "sed -n '1p'";
      snd = "sed -n '2p'";
      # ls = "LC_ALL=C ${coreutils}/bin/ls --color=auto --group-directories-first";
      ls = "lsd";
      la = "${ls} -A";
      l = "${ls} -Alho";
      map = "xargs -n1";
      maplines = "xargs -n1 -0";
      dmesg = "dmesg -H";
      rg = "rg --glob '!package-lock.json' --glob '!.git/*' --glob '!yarn.lock' --glob '!.yarn/*' --smart-case --hidden";
      grep = rg;
      tg = "tree-grepper";
      tree = "tree -a --dirsfirst -I .git";
      tl = "tldr";
      less = "less -R";

      # 5 second countdown until the clipboard gets typed out
      type-clipboard = ''
        sh -c 'sleep 5.0; ydotool type -- "$(wl-paste)"'
      '';

      # Force adoption of unifi devices
      adopt = ''
        for x in 1 2 3; do
          echo "192.168.1.$x set-inform http://192.168.1.4:8080/inform"
          ssh ${user}@192.168.1.$x "/usr/bin/mca-cli-op set-inform http://192.168.1.4:8080/inform ; exit"
        done
      '';

      # Bashly CLI
      bashly = "docker run --rm -it --user $(id -u):$(id -g) --volume \"$PWD:/app\" dannyben/bashly";

      j = "journalctl";
      s = "sudo systemctl";
      sz = "sudo sysz";

    };

  };

}
