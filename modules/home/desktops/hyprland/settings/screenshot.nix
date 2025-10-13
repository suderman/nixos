{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      ", print, exec, hypr-screenshot screen" # screen to clipboard
      "alt, print, exec, hypr-screenshot color" # color picker
    ];
  };
}
