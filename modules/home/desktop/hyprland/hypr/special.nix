{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Super+Shift+p to toggle visibility of floating windows on each workspace
      "super+shift, p, exec, hypr-togglefullscreenorhidden"

      # Toggle special workspace
      "super, escape, togglespecialworkspace"

      # Minimize windows (send to special workspace) and restore
      "super+alt, escape, exec, hypr-togglespecial" # movetoworkspacesilent special
    ];
  };
}
