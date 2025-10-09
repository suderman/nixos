{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Screenshot a region
      ", print, exec, hypr-screenshot ri"
      "super, print, exec, hypr-screenshot rf"
      "ctrl, print, exec, hypr-screenshot rc"
      "shift, print, exec, hypr-screenshot sc"
      "super+shift, print, exec, hypr-screenshot sf"
      "ctrl+shift, print, exec, hypr-screenshot si"
      "alt, print, exec, hypr-screenshot p"
    ];
  };
}
