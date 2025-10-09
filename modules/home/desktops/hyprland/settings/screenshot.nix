{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      ", print, exec, hypr-screenshot sc" # screen to clipboard
      "shift, print, exec, hypr-screenshot sf" # screen to file
      "alt, print, exec, hypr-screenshot p" # color picker
    ];

    bindo = [
      ", print, exec, hypr-screenshot ri" # region to interactive
      "shift, print, exec, hypr-screenshot si" # screen to interactive
    ];
  };
}
