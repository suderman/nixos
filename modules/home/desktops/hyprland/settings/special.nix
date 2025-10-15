{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Super+p to toggle presence of floating windows on each workspace
      "super, p, exec, hypr-togglefloatingspecial"

      # Toggle special workspace
      "super, escape, togglespecialworkspace"

      # Minimize windows (send to special workspace) and restore
      "super+alt, escape, exec, hypr-togglespecial" # movetoworkspacesilent special
    ];
  };
}
