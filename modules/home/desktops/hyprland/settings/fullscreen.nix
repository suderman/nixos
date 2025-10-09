{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      "super, f, fullscreen, 1" # (focus)
      "super+alt, f, fullscreen, 0" # (full)
    ];
    bindo = [
      "super, f, fullscreen, 0" # (full on longpress)
    ];
  };
}
