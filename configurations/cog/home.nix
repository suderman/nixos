{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  # Window manager
  # modules.hyprland.enable = true;

  # terminal du jour
  modules.kitty.enable = true;

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

    joypixels
    jetbrains-mono

    gst_all_1.gst-libav

    isy
    lapce
    anytype-wayland
    micro
    quickemu
    xorg.xeyes
    yt-dlp
    # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...

    _1password
    _1password-gui
    darktable
    digikam
    # dolphin-emu
    firefox-wayland
    inkscape
    junction
    libreoffice 
    newsflash
    unstable.nodePackages_latest.immich
    unstable.owncloud-client

    beeper
    tdesktop
    slack

    libsForQt5.kdenlive

    join-desktop

    unstable.yuzu-mainline

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
  };


  # modules.firefox-pwa.enable = true;
  # home.file.".ssh/id_ed25519".source = "/nix/keys/id_ed25519";

}
