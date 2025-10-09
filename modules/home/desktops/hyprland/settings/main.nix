{
  lib,
  pkgs,
  perSystem,
  ...
}: let
  init = perSystem.self.mkScript {
    path = with pkgs; [coreutils];
    text = lib.concatStringsSep "\n" [
      # Temporary symlink
      "ln -sf $XDG_RUNTIME_DIR/hypr /tmp/hypr"

      # Ensure portals and other systemd user services are running
      "bounce"
    ];
  };
in {
  wayland.windowManager.hyprland.settings = {
    # default display
    monitor = [", preferred, 0x0, 1"];

    # Let xwayland be tiny, not blurry
    xwayland.force_zero_scaling = true;

    # Execute at launch
    exec-once = ["${init}"];

    input = {
      kb_layout = "us";
      follow_mouse = 1;
      natural_scroll = true;
      scroll_factor = 1.5;
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        clickfinger_behavior = true;
        scroll_factor = 0.7;
      };
      scroll_method = "2fg";
      sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
    };

    general = {
      layout = "dwindle";
      resize_on_border = true;
      snap = {
        enabled = true;
        window_gap = 10;
        monitor_gap = 10;
        border_overlap = true;
      };
    };

    dwindle = {
      preserve_split = true;
      smart_split = false;
      pseudotile = true;
      special_scale_factor = 0.9;
      split_width_multiplier = 1.35;
      single_window_aspect_ratio = "4 3"; # constrain width of single windows
    };

    gesture = [
      "3, horizontal, workspace"
      "3, vertical, special, special"
    ];

    misc = {
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;
      enable_swallow = false;
      swallow_regex = "^(Alacritty|kitty|footclient)$";
      swallow_exception_regex = "wev|^(*.Yazi.*)$|^(*.mpv.*)$|^(*.imv.*)$|^(*.nvim.*)$";
      focus_on_activate = false;
      new_window_takes_over_fullscreen = 2; # unfullscreen when opening new window
    };

    "binds:workspace_back_and_forth" = true;

    bind = [
      # Exit hyprland
      "super+shift, q, exit,"
    ];
  };
}
