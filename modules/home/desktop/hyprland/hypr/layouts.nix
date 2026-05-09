{...}: {
  wayland.windowManager.hyprland.settings = {
    layout = {
      single_window_aspect_ratio = "4 3"; # constrain width of single windows
      single_window_aspect_ratio_tolerance = 0.1;
    };

    general.layout = "dwindle"; # default layout

    dwindle = {
      preserve_split = true;
      smart_split = false;
      special_scale_factor = 0.9;
      split_width_multiplier = 1.35;
    };

    master = {
      orientation = "left"; # left right top bottom center
      mfact = 0.75; # 0.55
      new_status = "master";
      new_on_top = true;
    };

    scrolling = {
      fullscreen_on_one_column = true;
      column_width = 0.40; # 0.5;
      focus_fit_method = 1; # 0 = center, 1 = fit
      follow_focus = true; # true;
      follow_min_visible = 0.4;
      direction = "right"; # down
    };

    # no monocle config (yet)
  };
}
