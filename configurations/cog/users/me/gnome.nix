{ config, options, lib, pkgs, this, ... }: let 
  # inherit (this.lib) apps;
in {
  
  modules.gnome = with pkgs; {
    dock = [
      kitty
      firefox
      gnome.nautilus
      telegram-desktop
      "app.bluebubbles.BlueBubbles"
      tauon
      gnome-text-editor
      "org.gimp.GIMP"
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
