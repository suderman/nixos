{ config, lib, pkgs, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    profiles.desktop # gui apps on all my desktops
    profiles.image-editing # graphics apps 
  ];

  home.packages = with pkgs; [ 
    plex-media-player
    plexamp
    telegram-desktop
    libreoffice
  ];

  programs.gnome-shell = with pkgs; {
    gnome-extensions = options.programs.gnome-shell.gnome-extensions.default ++ [
      gnomeExtensions.dash-to-dock
    ];
    dock = [
      firefox
      nautilus
      telegram-desktop
      gnome-calendar
      gnome-text-editor
      gnome-calculator
    ];
    wallpapers = let dir = config.home.homeDirectory; in [ 
      "${dir}/.light.jpg" "${dir}/.dark.jpg" 
    ];
  };

}
