{ config, options, lib, pkgs, ... }: {
  
  modules.gnome = with pkgs; {
    dock = [
      kitty
      firefox
      gnome.nautilus
      telegram-desktop
      tauon
      gnome-text-editor
    ];
    extensions = options.modules.gnome.extensions.default ++ [
      gnomeExtensions.dash-to-dock
      gnomeExtensions.gsconnect
    ];
    wallpapers = let dir = config.home.homeDirectory; in [ 
      "${dir}/.light.jpg" "${dir}/.dark.jpg" 
    ];
  };

}
