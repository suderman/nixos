# windows
{...}: {
  wayland.windowManager.hyprland.settings = {
    bindm = [
      # Move/resize windows with super + LMB/RMB and dragging
      "super, mouse:272, movewindow"
      "super, mouse:273, resizewindow"
    ];

    binde = [
      # Move a window with super+alt [hjkl] (hold to repeat)
      "super+alt, h, exec, hypr-movewindoworgrouporactive l -40 0"
      "super+alt, j, exec, hypr-movewindoworgrouporactive d 0 40"
      "super+alt, k, exec, hypr-movewindoworgrouporactive u 0 -40"
      "super+alt, l, exec, hypr-movewindoworgrouporactive r 40 0"

      # Resize a window with super+shift [hjkl] (hold to repeat)
      "super+shift, h, resizeactive, -80 0"
      "super+shift, j, resizeactive, 0 80"
      "super+shift, k, resizeactive, 0 -80"
      "super+shift, l, resizeactive, 80 0"
    ];

    # when toggling float/tile, hold down key to pin/pseudo it too
    bindo = ["super, o, exec, hypr-togglepinorpseudo"];

    bind = [
      # Move focus to a window with super [hjkl]
      "super, h, movefocus, l"
      "super, j, movefocus, d"
      "super, k, movefocus, u"
      "super, l, movefocus, r"

      # Kill the active window
      "super, w, killactive,"

      # Cycle floating window's position around screen (floating) or split (tiled)
      "super, i, exec, hypr-togglesplitorcycle"
      "super+shift, i, exec, hypr-togglesplitorcycle reverse"

      # Toggle pin (floating) or pseudo (tiled)
      "super, p, exec, hypr-togglepinorpseudo"

      # Back-and-forth with super \
      "super, backslash, focuscurrentorlast"

      # Focus urgent windows
      "super, u, focusurgentorlast"

      # Navigation windows with super tab
      "super, tab, exec, hypr-supertab"
      "super+alt, tab, exec, hypr-supertab next"
      "super+shift, tab, exec, hypr-supertab prev"

      # Resize active window to various presets
      "super+shift, 1, resizeactive, exact 10% 10%"
      "super+shift, 1, centerwindow, 1"
      "super+shift, 2, resizeactive, exact 20% 20%"
      "super+shift, 2, centerwindow, 1"
      "super+shift, 3, resizeactive, exact 30% 30%"
      "super+shift, 3, centerwindow, 1"
      "super+shift, 4, resizeactive, exact 40% 40%"
      "super+shift, 4, centerwindow, 1"
      "super+shift, 5, resizeactive, exact 50% 50%"
      "super+shift, 5, centerwindow, 1"
      "super+shift, 6, resizeactive, exact 60% 60%"
      "super+shift, 6, centerwindow, 1"
      "super+shift, 7, resizeactive, exact 70% 70%"
      "super+shift, 7, centerwindow, 1"
      "super+shift, 8, resizeactive, exact 80% 80%"
      "super+shift, 8, centerwindow, 1"
      "super+shift, 9, resizeactive, exact 90% 90%"
      "super+shift, 9, centerwindow, 1"

      "super+shift, 0, centerwindow, 1"
      "super+shift, O, resizeactive, exact 600 400"
    ];
  };
}
