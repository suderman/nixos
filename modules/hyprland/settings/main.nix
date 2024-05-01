{ lib, ... }: let inherit (lib) mkDefault; in {

  monitor = [
    # default display
    ", preferred, 0x0, 1"
  ];

  # Let xwayland be tiny, not blurry
  xwayland.force_zero_scaling = true;

  # Execute your favorite apps at launch
  exec-once = [
    # "hyprpaper"
    "mako"
    "swww-daemon"
  ];

  input = {
    kb_layout = "us";
    follow_mouse = 1;
    natural_scroll = true;
    touchpad = {
      natural_scroll = true;
      disable_while_typing = true;
      clickfinger_behavior = true;
      scroll_factor = 0.7;
    };
    scroll_method = "2fg";
    sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
  };

  # "device:epic-mouse-v1" = { sensitivity = -0.5; };

  general = {
    layout = mkDefault "master";
    no_cursor_warps = mkDefault false;
    resize_on_border = mkDefault true;
  };

  gestures.workspace_swipe = mkDefault true;
  master.new_is_master = mkDefault true;

  misc = {
    mouse_move_enables_dpms = mkDefault true;
    key_press_enables_dpms = mkDefault true;
    enable_swallow = mkDefault true;
    swallow_regex = mkDefault "^(Alacritty|kitty|footclient)$";
    focus_on_activate = mkDefault true;
  };

}
