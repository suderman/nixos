{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # # Super+m to minimize window, Super+m to bring it back (possibly on a different workspace)
      # "super, m, togglespecialworkspace, mover"
      # "super, m, movetoworkspace, +0"
      # "super, m, togglespecialworkspace, mover"
      # "super, m, movetoworkspace, special:mover"
      # "super, m, togglespecialworkspace, mover"

      # Super+p to toggle presence of floating windows on each workspace
      "super, p, exec, hypr-togglefloatingspecial"

      # Toggle special workspace
      "super, escape, togglespecialworkspace"

      # Minimize windows (send to special workspace) and restore
      "super+alt, escape, exec, hypr-togglespecial" # movetoworkspacesilent special

      # Toggle marked window
      "super, m, exec, hypr-togglemark toggle"
    ];

    bindo = [
      # Clear all marked windows
      "super, m, exec, hypr-togglemark clear"
    ];
  };
}
