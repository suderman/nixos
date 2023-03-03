{ config, lib, pkgs, ... }: {

  base.enable = true;
  secrets.enable = true;

  # ---------------------------------------------------------------------------
  # Home Enviroment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    # dolphin
    # signal-desktop
    # webex
    linode-cli
    _1password
    _1password-gui
    element-desktop
    firefox-wayland
    joypixels
    libreoffice 
    nerdfonts
    newsflash
    nur.repos.mic92.hello-nur
    owncloud-client
    owofetch
    neofetch
    plexamp
    slack
    tdesktop
    unstable.nnn 
    unstable.sl
    xorg.xeyes
    yo
    systemdgenie
    pick
    # keygen
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
  };


  # home.file.".ssh/id_ed25519".source = "/nix/keys/id_ed25519";

}
