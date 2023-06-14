{ config, lib, pkgs, gui, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  # Window manager
  # modules.hyprland.enable = true;

  modules.hyprland.enable = (if gui == "hyprland" then true else false);
  modules.anyrun.enable = true;

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

    nerdfonts
    joypixels

    isy
    lapce
    micro
    quickemu
    xorg.xeyes
    yt-dlp
    # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...

    _1password
    _1password-gui
    darktable
    digikam
    dolphin-emu
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

  ];

  programs = {
    # neovim.enable = true;
    chromium.enable = true;
    git.enable = true;
    tmux.enable = true;
    wezterm.enable = true;
    kitty.enable = true;
    zsh.enable = true;
    dconf.enable = true;
    foot.enable = true;
  };


  # modules.firefox-pwa.enable = true;
  # home.file.".ssh/id_ed25519".source = "/nix/keys/id_ed25519";

}
