{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    # default display
    monitor = [", preferred, 0x0, 1"];

    # Let xwayland be tiny, not blurry
    xwayland.force_zero_scaling = true;

    # Run once at start
    exec-once = let
      waybarwatcher = pkgs.self.mkScript {
        path = [pkgs.socat pkgs.procps];
        text =
          # bash
          ''
            handle() {
              case $1 in
              workspacev2\>\>*)
                pkill -RTMIN+8 waybar
                ;;
              esac
            }
            socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
          '';
      };
    in ["${waybarwatcher}"];

    # Run at start and every reload
    exec = [
      # Send refresh signal to waybar for initial display
      "pkill -RTMIN+8 waybar"

      # Pre-spawn browser process
      "chromium --no-startup-window"
    ];

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
      resize_on_border = true;
      snap = {
        enabled = true;
        window_gap = 10;
        monitor_gap = 10;
        border_overlap = true;
      };
    };

    gesture = [
      "3, vertical, workspace"
      "3, left, dispatcher, layoutmsg, move +col"
      "3, right, dispatcher, layoutmsg, move -col"
    ];

    misc = {
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;
      enable_swallow = false;
      swallow_regex = "^(Alacritty|kitty|footclient)$";
      swallow_exception_regex = "wev|^(*.Yazi.*)$|^(*.mpv.*)$|^(*.imv.*)$|^(*.nvim.*)$";
      focus_on_activate = false;
      on_focus_under_fullscreen = 2; # unfullscreen when opening new window
    };

    "binds:workspace_back_and_forth" = false;

    bind = [
      # Exit hyprland
      "super+shift, q, exit,"
    ];
  };
}
