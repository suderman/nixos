{ config, lib, pkgs, ... }: {

  imports = [ ../. ];

  # ---------------------------------------------------------------------------
  # Home Enviroment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    # dolphin
    # signal-desktop
    # webex
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
    plexamp
    slack
    tdesktop
    unstable.nnn 
    unstable.sl
    xorg.xeyes
    yo
  ];

  programs = {
    # neovim.enable = true;
    chromium.enable = true;
    git.enable = true;
    tmux.enable = true;
    wezterm.enable = true;
    zsh.enable = true;
  };

  # home.file.".ssh/id_ed25519".source = "/nix/keys/id_ed25519";
  
  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
  };


}
