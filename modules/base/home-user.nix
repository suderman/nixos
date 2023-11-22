{ config, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  # Add support for ~/.local/bin
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Aliases 
  home.shellAliases = with pkgs; rec {
    df = "df -h";
    du = "du -ch --summarize";
    fst = "sed -n '1p'";
    snd = "sed -n '2p'";
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
        ssh $USER@192.168.1.$x "/usr/bin/mca-cli-op set-inform http://192.168.1.4:8080/inform; exit"
      done
    '';

    # Bashly CLI
    bashly = "docker run --rm -it --user $(id -u):$(id -g) --volume \"$PWD:/app\" dannyben/bashly";

    j = "journalctl";
    s = "sudo systemctl";
    sz = "sudo sysz";

  };

  xdg.userDirs = with config.home; {
    enable = true;
    createDirectories = false;
    download = "${homeDirectory}/tmp";
    desktop = "${homeDirectory}/data";
    documents = "${homeDirectory}/data/documents";
    music = "${homeDirectory}/data/music";
    pictures = "${homeDirectory}/data/images";
    videos = "${homeDirectory}/data/videos";
    # publicShare = "${homeDirectory}/public";
  };

  # Attempts to make Wayland work. Was needed at the time, probably not anymore. Need to clean this up.
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    # WAYLAND_DISPLAY = "wayland-0";
    # QT_WAYLAND_FORCE_DPI = "physical";
    # QT_SCALE_FACTOR = "1.25";
    # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # SAL_USE_VCLPLUGIN = "gtk3";
  };

}
