{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      ", print, exec, printscreen image"
      "alt, print, exec, printscreen video"
      "shift, print, exec, printscreen video"
      "ctrl, print, exec, printscreen color"
    ];
  };
}
