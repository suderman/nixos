{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    # Sushi (Quick Look)
    xdg.desktopEntries."org.gnome.NautilusPreviewer" = {
      name = "Sushi";
      icon = "image-viewer";
      noDisplay = true;
    };

    # GIMP
    xdg.desktopEntries."gimp-2.99" = {
      name = "GIMP";
      icon = "org.gimp.GIMP";
      noDisplay = true;
    };

  };
}
