{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) concatStringsSep mkDefault mkIf mkShellScript;

  init = mkShellScript {
    inputs = with pkgs; [ coreutils swww ]; text = concatStringsSep "\n" [ 

      # Temporary symlink
      "ln -sf $XDG_RUNTIME_DIR/hypr /tmp/hypr"

      # Ensure portals and other systemd user services are running
      "bounce"

      # Wallpaper
      "swww-daemon"

    ];
  };

in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {

      # default display
      monitor = [ ", preferred, 0x0, 1" ];

      # Let xwayland be tiny, not blurry
      xwayland.force_zero_scaling = true;

      # Execute at launch
      exec-once = [ "${init}" ];

      input = {
        kb_layout = "us";
        # follow_mouse = mkDefault 2;
        follow_mouse = mkDefault 1;
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

      # "device:epic-mouse-v1" = { sensitivity = -0.5; };

      general = {
        layout = mkDefault "dwindle";
        resize_on_border = mkDefault true;
      };

      dwindle = {
        preserve_split = true;
        smart_split = false;
        pseudotile = true;
        special_scale_factor = 0.9;
        split_width_multiplier = 1.35;
      };

      gestures.workspace_swipe = mkDefault true;

      misc = {
        mouse_move_enables_dpms = mkDefault true;
        key_press_enables_dpms = mkDefault true;
        enable_swallow = mkDefault true;
        swallow_regex = mkDefault "^(Alacritty|kitty|footclient)$";
        focus_on_activate = mkDefault false;
        # cursor_zoom_factor = mkDefault 1;
        new_window_takes_over_fullscreen = 2; # unfullscreen when opening new window
      };

      binds = {
         workspace_back_and_forth = mkDefault true;
      };

    };
  };

}
