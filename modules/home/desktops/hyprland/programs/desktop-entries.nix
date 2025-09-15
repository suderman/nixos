{...}: {
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
}
