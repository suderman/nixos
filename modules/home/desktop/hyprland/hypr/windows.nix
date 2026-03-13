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

      # Move entire column with super+alt+shift [hl] (scrolling layout)
      "super+alt+shift, h, layoutmsg, swapcol l"
      "super+alt+shift, l, layoutmsg, swapcol r"

      # Resize a window with super+shift [hjkl] (hold to repeat)
      "super+shift, h, resizeactive, -80 0"
      "super+shift, j, resizeactive, 0 80"
      "super+shift, k, resizeactive, 0 -80"
      "super+shift, l, resizeactive, 80 0"

      # Move focus to a window with super [hjkl]
      "super, h, movefocus, l"
      "super, j, movefocus, d"
      "super, k, movefocus, u"
      "super, l, movefocus, r"
    ];

    # Run script again if o key held down
    bindo = [
      "super, i, exec, hypr-tile"
      "super+alt, i, exec, hypr-tile alt"
    ];

    bind = [
      # Set window tiled, or togglesplit if already tiled
      "super, i, exec, hypr-tile"

      # Set window tiled, or swapsplit if already tiled
      "super+alt, i, exec, hypr-tile alt"

      # Focus tiled windows in workspace
      "super+shift, i, cyclenext, tiled"

      # Master layout add/remove master window
      "super+alt, m, layoutmsg, addmaster"
      "super+alt+shift, m, layoutmsg, removemaster"

      # Kill the active window
      "super, w, killactive,"

      # Focus urgent windows
      "super, u, focusurgentorlast"

      # Back-and-forth with super \
      "super, backslash, focuscurrentorlast"
    ];
  };
}
