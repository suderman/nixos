{ config, options, lib, pkgs, this, ... }: let 
  inherit (lib) mkOptionDefault;
in {

  home.packages = with pkgs; [ 
    neofetch
    yo
    firefox-wayland
    dolphin
    plex-media-player
    plexamp
    telegram-desktop
    libreoffice
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

  programs.gnome-shell = with pkgs; {
    gnome-extensions = options.programs.gnome-shell.gnome-extensions.default ++ [
      gnomeExtensions.dash-to-dock
    ];
    dock = [
      firefox
      gnome.nautilus
      telegram-desktop
      gnome.gnome-calendar
      gnome-text-editor
      gnome.gnome-calculator
    ];
    wallpapers = let dir = config.home.homeDirectory; in [ 
      "${dir}/.light.jpg" "${dir}/.dark.jpg" 
    ];
  };

}
