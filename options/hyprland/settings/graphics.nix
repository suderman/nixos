{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkDefault mkForce; 

in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {

      # env = [
      #   "XCURSO_SIZE,84"
      # ];

      general = {
        gaps_in = "10, 10, 5, 10";
        gaps_out = "10, 20, 20, 20";
        gaps_workspaces = 20;
        border_size = 3;
        "col.active_border" = mkDefault "rgba(89b4facc) rgba(cba6f7cc) 270deg";
        "col.inactive_border" = mkDefault "rgba(11111b66) rgba(b4befe66) 270deg";
        extend_border_grab_area = 20; # gaps between windows can be used for resizing
      };

      group = {
        merge_groups_on_drag = true;
        groupbar.enabled = false;
        "col.border_active" = mkForce "rgba(FF5F1Fcc) rgba(FF5F1Fcc) 270deg";
        "col.border_inactive" = mkForce "rgba(FF5F1F80) rgba(FF5F1F80) 270deg";

        "col.border_locked_active" = mkForce "rgba(F1C40Fcc) rgba(16A085cc) 270deg";
        "col.border_locked_inactive" = mkForce "rgba(F1C40F80) rgba(16A08580) 270deg";
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = false;
      };

      decoration = {
        rounding = 10;

        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
          offset = "0, 3";
          color = mkDefault "rgba(00000080)";
        };

        dim_inactive = false;
        dim_strength = 0.1;
        dim_special = 0.5;

        blur = {
          enabled = true;
          size = 4;
          passes = 3;
          ignore_opacity = true;
          special = true;
          xray = true;
        };
      };


      animations = {
        enabled = true;

        bezier = [
          "overshot, 0.05, 0.9, 0.1, 1.05"
          "smoothOut, 0.36, 0, 0.66, -0.56"
          "smoothIn, 0.25, 1, 0.5, 1"

          "win, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"

          "md3_standard, 0.2, 0.0, 0, 1.0"
          "md3_decel, 0.05, 0.7, 0.1, 1"
          "md3_accel, 0.3, 0, 0.8, 0.15"
          "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
          "win10, 0, 0, 0, 1"
          "gnome, 0, 0.85, 0.3, 1"
          "funky, 0.46, 0.35, -0.2, 1.2"
        ];

        animation = [
          "windows, 1, 3, overshot, slide"
          "windowsOut, 1, 3, smoothOut, slide"
          "windowsMove, 1, 3, default"
          "border, 1, 3, default"
          "borderangle, 1, 20, liner, once"
          "fade, 1, 3, smoothIn"
          "fadeDim, 1, 3, smoothIn"
          "workspaces, 1, 3, default"
          "specialWorkspace, 1, 3, overshot, slidefadevert -50%"
          "layers, 1, 0.1, default, fade"
        ];

      };

      # animation slide/popin/fade
      layerrule = [
        "animation slide, notifications"
        "animation slide, waybar"
        "animation fade, swww-daemon"
        "animation fade, wofi"
        "animation slide, menu"
        "dimaround, menu"
        "animation fade, rofi"
        "dimaround, rofi"
      ];

    };
  };

}
