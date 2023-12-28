{ config, options, lib, pkgs, this, ... }: let 

  inherit (lib) mkOptionDefault;
  inherit (this.lib) apps;

in {

  home.packages = with pkgs; [ 
    neofetch
    yo
    firefox-wayland
    dolphin
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

  # terminal du jour
  modules.kitty.enable = true;

  modules.gnome = with apps; {
    extensions = options.modules.gnome.extensions.default ++ [
      dash-to-dock
    ];
    dock = with apps; [
      firefox
      nautilus
      telegram
      calendar
      text-editor
      calculator
    ];
    wallpapers = let dir = config.home.homeDirectory; in [ 
      "${dir}/.light.jpg" "${dir}/.dark.jpg" 
    ];
  };

}
