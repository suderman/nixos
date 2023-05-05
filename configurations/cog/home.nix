{ config, lib, pkgs, ... }: {

  modules.base.enable = true;
  modules.secrets.enable = true;

  # ---------------------------------------------------------------------------
  # Home Enviroment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    _1password
    _1password-gui
    bat 
    cargo
    cowsay
    darktable
    element-desktop
    exa
    firefox-wayland
    fish
    inkscape
    joypixels
    killall
    lf 
    libreoffice 
    linode-cli
    lsd
    micro
    mosh
    nano
    neofetch
    nerdfonts
    newsflash
    nodejs
    nsxiv
    nur.repos.mic92.hello-nur
    owofetch
    plexamp
    python39
    python39Packages.pip
    python39Packages.virtualenv
    ripgrep
    slack
    # systemdgenie
    sysz
    tdesktop
    tealdeer
    unstable.nnn 
    unstable.sl
    wget
    xorg.xeyes
    yo

    junction

    # keygen
    # dolphin
    # signal-desktop
    # webex

    isy

    unstable.nodePackages_latest.immich

    unstable.quickemu

    yt-dlp
    # yt-dlp -f mp4-240p -x --audio-format mp3 https://rumble.com/...

    nextcloud-client
    unstable.owncloud-client


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
