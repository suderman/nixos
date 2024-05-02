{ lib, ... }: let inherit (lib) mkDefault; in {

  env = [
    "XCURSO_SIZE,84"
  ];

  general = {
    gaps_in = mkDefault 4;
    gaps_out = mkDefault 8;
    border_size = mkDefault 2;
    "col.active_border" = mkDefault "rgb(89b4fa) rgb(cba6f7) 270deg";
    "col.inactive_border" = mkDefault "rgb(11111b) rgb(b4befe) 270deg";
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
    blur.special = mkDefault false;
  };

  animations = {
    enabled = mkDefault true;
    bezier = mkDefault [

      "win, 0.05, 0.9, 0.1, 1.05"
      "winIn, 0.1, 1.1, 0.1, 1.1"
      "winOut, 0.3, -0.3, 0, 1"
      "liner, 1, 1, 1, 1"

      "md3_standard, 0.2, 0.0, 0, 1.0"
      "md3_decel, 0.05, 0.7, 0.1, 1"
      "md3_accel, 0.3, 0, 0.8, 0.15"
      "overshot, 0.05, 0.9, 0.1, 1.05"
      "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
      "win10, 0, 0, 0, 1"
      "gnome, 0, 0.85, 0.3, 1"
      "funky, 0.46, 0.35, -0.2, 1.2"
    ];

    animation = mkDefault [

     "windows, 1, 5, win, slide"
     "windowsIn, 1, 6, winIn, slide"
     "windowsOut, 1, 5, winOut, slide"
     # "border, 1, 1, liner"
     "border, 1, 1, default"
     "borderangle, 1, 30, liner, loop"
     "fade, 1, 10, default"
     "workspaces, 1, 5, win"
     "specialWorkspace, 1, 3, default, slidefadevert -50%"


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
