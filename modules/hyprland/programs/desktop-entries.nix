{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    xdg.desktopEntries = {

      # Sushi (Quick Look)
      "org.gnome.NautilusPreviewer" = {
        name = "Sushi";
        icon = "image-viewer";
        noDisplay = true;
      };

      # GIMP
      "gimp-2.99" = {
        name = "GIMP";
        icon = "org.gimp.GIMP";
        noDisplay = true;
      };

    };

  };
}
