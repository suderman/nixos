{ config, options, lib, pkgs, this, ... }: let 
  inherit (this.lib) apps;
in {
  
  modules.gnome = with apps; {
    dock = [
      kitty
      firefox
      nautilus
      telegram
      text-editor
    ];
    extensions = options.modules.gnome.extensions.default ++ [
      dash-to-dock
    ];
    wallpapers = let dir = config.home.homeDirectory; in [ 
      "${dir}/.light.jpg" "${dir}/.dark.jpg" 
    ];
  };

}
