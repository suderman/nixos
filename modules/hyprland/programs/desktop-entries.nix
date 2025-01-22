{ config, lib, pkgs, ... }: let
  inherit (lib) mkIf;
in {

  config = mkIf config.wayland.windowManager.hyprland.enable {
    xdg.desktopEntries = {

      # GIMP
      "gimp-2.99" = {
        name = "GIMP"; 
        icon = "org.gimp.GIMP"; 
        noDisplay = true;
      };

      # Sushi (Quick Look)
      "org.gnome.NautilusPreviewer" = {
        name = "Sushi"; 
        icon = "image-viewer"; 
        noDisplay = true;
      };

    };
  };
}
