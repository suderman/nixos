# modules.hyprland.enable = true;
{ config, lib, pkgs, inputs, ... }: 

let 
  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkDefault;

in {

  wayland.windowManager.hyprland.settings = mkIf cfg.enable {

    monitor = mkDefault [
      # embedded display (laptop)
      "eDP-1, 2256x1504@59.9990001, 500x1440, 1.4"
      # default display
      ", preferred, 0x0, 1"
    ];

    # Let xwayland be tiny, not blurry
    xwayland.force_zero_scaling = true;

    # Execute your favorite apps at launch
    exec-once = [
      "hyprpaper"
      "mako"
    ];

    env = mkDefault [
      "XCURSO_SIZE,84"
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
      gaps_in = 4;
      gaps_out = 8;
      border_size = 2;
      "col.active_border" = "rgb(89b4fa) rgb(cba6f7) 270deg";
      "col.inactive_border" = "rgb(11111b) rgb(b4befe) 270deg";
      "col.group_border" = "rgb(313244)";
      "col.group_border_active" = "rgb(f5c2e7)";
      layout = "master";
      no_cursor_warps = false;
      resize_on_border = true;
    };

    gestures.workspace_swipe = true;
    master.new_is_master = true;

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;
      enable_swallow = true;
      swallow_regex = "^(Alacritty|kitty|footclient)$";
      focus_on_activate = true;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;
      # suppress_portal_warnings = true;
    };

    decoration = {
      rounding = 15;
      drop_shadow = true;
      shadow_range = 4;
      shadow_render_power = 3;
      col.shadow = "rgba(1a1a1aee)";
      dim_inactive = false;
      dim_strength = 0.1;
      dim_special = 0;
    };

    animations = {
      enabled = true;
      bezier =  [
        "md3_standard, 0.2, 0.0, 0, 1.0"
        "md3_decel, 0.05, 0.7, 0.1, 1"
        "md3_accel, 0.3, 0, 0.8, 0.15"
        "overshot, 0.05, 0.9, 0.1, 1.05"
        "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
        "win10, 0, 0, 0, 1"
        "gnome, 0, 0.85, 0.3, 1"
        "funky, 0.46, 0.35, -0.2, 1.2"
      ];
      animation = [
        "windows, 1, 2, md3_decel, slide"
        "animation = border, 1, 10, default"
        "animation = fade, 1, 0.0000001, default"
        "animation = workspaces, 1, 4, md3_decel, slide"
      ];
    };

    bind = [
      "SUPER, Return, exec, kitty"
      "SUPER, Q, killactive,"
      "SUPERSHIFT, Q, exit,"
      "SUPER, E, exec, nautilus"
      "SUPER, F, exec, firefox"
      "SUPER, Escape, togglefloating,"
      "SUPER, Space, exec, tofi-drun --drun-launch=true"
      "SUPER, N, layoutmsg, swapnext"
      "SUPER, P, layoutmsg, swapprev"
      "SUPER, B, layoutmsg, swapwithmaster master"
      "SUPER, G, layoutmsg, addmaster "
      "SUPER+SHIFT, G, layoutmsg, removemaster"

      # Move focus with mainMod + arrow keys
      "SUPER, H, movefocus, l"
      "SUPER, J, movefocus, d"
      "SUPER, K, movefocus, u"
      "SUPER, L, movefocus, r"

      "SUPERSHIFTCONTROL, J, layoutmsg, swapnext"
      "SUPERSHIFTCONTROL, K, layoutmsg, swapprev"
      "SUPER, M, layoutmsg, swapwithmaster master"

      # Switch workspaces with mainMod + [0-9]
      "SUPER, 1, workspace, 1"
      "SUPER, 2, workspace, 2"
      "SUPER, 3, workspace, 3"
      "SUPER, 4, workspace, 4"
      "SUPER, 5, workspace, 5"
      "SUPER, 6, workspace, 6"
      "SUPER, 7, workspace, 7"
      "SUPER, 8, workspace, 8"
      "SUPER, 9, workspace, 9"
      "SUPER, 0, workspace, 10"

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      "SUPER SHIFT, 1, movetoworkspace, 1"
      "SUPER SHIFT, 2, movetoworkspace, 2"
      "SUPER SHIFT, 3, movetoworkspace, 3"
      "SUPER SHIFT, 4, movetoworkspace, 4"
      "SUPER SHIFT, 5, movetoworkspace, 5"
      "SUPER SHIFT, 6, movetoworkspace, 6"
      "SUPER SHIFT, 7, movetoworkspace, 7"
      "SUPER SHIFT, 8, movetoworkspace, 8"
      "SUPER SHIFT, 9, movetoworkspace, 9"
      "SUPER SHIFT, 0, movetoworkspace, 10"

      # Scroll through existing workspaces with mainMod + scroll
      "SUPER, mouse_down, workspace, e+1"
      "SUPER, mouse_up, workspace, e-1"
    ];

    binde = [
      "SUPERSHIFT, H, resizeactive, -80 0"
      "SUPERSHIFT, J, resizeactive, 0 80"
      "SUPERSHIFT, K, resizeactive, 0 -80"
      "SUPERSHIFT, L, resizeactive, 80 0"

      # Screen brightness
      ", XF86MonBrightnessUp,exec,brightnessctl set +5%"
      ", XF86MonBrightnessDown,exec,brightnessctl set 5%-"

      # Volume control
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ];

    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
      "SUPERSHIFT, mouse:272, resizewindow"
    ];

  };

}
