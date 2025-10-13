{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      ", print, exec, satty-screenshot"
      "alt, print, exec, hyprpicker -a && notify-send $(wl-paste)"
    ];
  };
}
