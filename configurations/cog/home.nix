{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  # ---------------------------------------------------------------------------
  # Home Enviroment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 

    bat 
    cowsay
    exa
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
    firefox-wayland
    inkscape
    junction
    libreoffice 
    newsflash
    unstable.nodePackages_latest.immich

    beeper
    tdesktop
    slack

    libsForQt5.kdenlive

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
    dconf.enable = true;

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

  # modules.firefox-pwa.enable = true;
  # home.file.".ssh/id_ed25519".source = "/nix/keys/id_ed25519";

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
