{ config, options, lib, pkgs, this, ... }: let 

  inherit (lib) mkOptionDefault;
  inherit (this.lib) apps;

in {

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

  # Packages
  home.packages = with pkgs; [ 

    bat 
    cowsay
    eza
    fish
    killall
    lf 
    linode-cli
    lsd
    mosh
    nano
    ncdu
    neofetch
    nnn 
    owofetch
    rclone
    ripgrep
    sl
    sysz
    tealdeer
    wget
    yo

    lazygit
    lazydocker
    parted
    imagemagick

    joypixels
    jetbrains-mono

    gst_all_1.gst-libav

    isy
    lapce
    # anytype-wayland
    micro
    quickemu
    xorg.xeyes
    yt-dlp # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...

    _1password
    _1password-gui
    darktable
    digikam
    firefox
    inkscape
    junction
    libreoffice 
    newsflash
    unstable.nodePackages_latest.immich

    beeper
    tdesktop
    slack

    libsForQt5.kdenlive

    bin-foo
    bin-bar

    withings-sync

    # join-desktop
    # unstable.yuzu-mainline
    # dolphin-emu

  ];

  programs = {
    # neovim.enable = true;
    chromium.enable = true;
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    wezterm.enable = false;
    foot.enable = false;

    obs-studio = with pkgs.unstable; {
      enable = true;
      package = obs-studio;
      # plugins = [ obs-studio-plugins.wlrobs ];
    };

    # pipewire-alsa pipewire-audio pipewire-docs pipewire-jack pipewire-media-session pipewire-pulse

  };


  modules.yazi.enable = true;

  # terminal du jour
  modules.kitty.enable = true;

  # File sync
  modules.ocis.enable = true;

  modules.gimp.enable = true;


  modules.gnome = with apps; {
    dock = [
      kitty
      firefox
      nautilus
      telegram
      text-editor
    ];
    extensions = options.modules.gnome.extensions.default ++ [
      dash-to-dock
    ];
    wallpapers = let dir = config.home.homeDirectory; in [ 
      "${dir}/.light.jpg" "${dir}/.dark.jpg" 
    ];
  };


  systemd.user.services.foobar-hm = {
    Unit = {
      Description = "Foobar Home-Manager";
      After = [ "graphical-session.target" ];
      Requires = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      Environment=''"FOO=bar"'';
      ExecStart = with pkgs; writeShellScript "foobar-hm" ''
        PATH=${lib.makeBinPath [ coreutils ]}
        touch /tmp/foobar-hm.txt
        date >> /tmp/foobar-hm.txt
      '';
    };
  };

}
