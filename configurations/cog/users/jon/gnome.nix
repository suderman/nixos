{ config, options, lib, pkgs, ... }: {
  
  modules.gnome = with pkgs; {
    dock = [
      kitty
      firefox
      nautilus
      telegram-desktop
      "app.bluebubbles.BlueBubbles"
      tauon
      gnome-text-editor
      "org.gimp.GIMP"
      # "com.cassidyjames.butler"
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
