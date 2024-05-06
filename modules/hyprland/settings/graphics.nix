{ lib, ... }: let inherit (lib) mkDefault; in {

  env = [
    "XCURSO_SIZE,84"
  ];

  general = {
    gaps_in = mkDefault 15;
    gaps_out = mkDefault 15;
    gaps_workspaces = mkDefault 20;
    border_size = mkDefault 5;
    "col.active_border" = mkDefault "rgba(89b4facc) rgba(cba6f7cc) 270deg";
    "col.inactive_border" = mkDefault "rgba(11111b66) rgba(b4befe66) 270deg";
    extend_border_grab_area = 100;
  };

  group = {
    groupbar.enabled = mkDefault false;
    "col.border_active" = mkDefault "rgba(FF5F1Fcc) rgba(FF5F1Fcc) 270deg";
    "col.border_inactive" = mkDefault "rgba(FF5F1F80) rgba(FF5F1F80) 270deg";

    "col.border_locked_active" = mkDefault "rgba(F1C40Fcc) rgba(16A085cc) 270deg";
    "col.border_locked_inactive" = mkDefault "rgba(F1C40F80) rgba(16A08580) 270deg";
  };

  dwindle = {
    no_gaps_when_only = mkDefault 2; # 1 hides borders, but can crash hyprland
  };

  misc = {
    disable_hyprland_logo = mkDefault true;
    disable_splash_rendering = mkDefault true;
    animate_manual_resizes = mkDefault true;
    animate_mouse_windowdragging = mkDefault false;
  };

  decoration = {
    rounding = mkDefault 15;
    drop_shadow = mkDefault true;
    shadow_range = mkDefault 4;
    shadow_render_power = mkDefault 3;
    "col.shadow" = mkDefault "rgba(1a1a1aee)";
    dim_inactive = mkDefault false;
    dim_strength = mkDefault 0.1;
    dim_special = mkDefault 0.5;
    blur.special = mkDefault true;
    blur.size = mkDefault 1;
    blur.passes = mkDefault 2;
    blur.xray = mkDefault true;
  };


  animations = {
    enabled = mkDefault true;
    bezier = mkDefault [

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

    animation = mkDefault [

      "windows, 1, 3, overshot, slide"
      "windowsOut, 1, 3, smoothOut, slide"
      "windowsMove, 1, 3, default"
      "border, 1, 3, default"
      "borderangle, 1, 20, liner, once"
      "fade, 1, 3, smoothIn"
      "fadeDim, 1, 3, smoothIn"
      "workspaces, 1, 3, default"
      "specialWorkspace, 1, 3, overshot, slidefadevert -50%"

      # "windows, 1, 5, win, slide"
      # "windowsIn, 1, 6, winIn, slide"
      # "windowsOut, 1, 5, winOut, slide"
      # "border, 1, 20, overshot"
      # "borderangle, 1, 20, liner, once"
      # "fade, 1, 10, default"
      # "workspaces, 1, 5, win"
      # "specialWorkspace, 1, 3, default, slidefadevert -50%"

      # "windows, 1, 2, overshot, popin"
      # # "windowsMove, 1, 1, md3_standard, slide"
      # "windowsMove, 0"
      # # "windows, 1, 2, md3_decel, popin"
      # "border, 1, 10, default"
      # "fade, 1, 0.0000001, default"
      # # "workspaces, 1, 4, md3_decel, slidefade"
      # "workspaces, 1, 4, hyprnostretch, slidefade"
      # "specialWorkspace, 1, 3, default, slidefadevert -50%"

    ];

  };


}
