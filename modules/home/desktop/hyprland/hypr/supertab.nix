{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Navigation windows with super tab
      "super, tab, exec, hypr-supertab"
      "super+alt, tab, exec, hypr-supertab next"
      "super+shift, tab, exec, hypr-supertab prev"

      # Toggle marked window
      "super, m, exec, hypr-supertab mark"
    ];

    bindo = [
      # Clear all marked windows
      "super, m, exec, hypr-supertab clear"
    ];

    windowrule = [
      "bordersize 1, tag:mark"
    ];
  };
}
