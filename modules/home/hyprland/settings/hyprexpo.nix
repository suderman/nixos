{ config, lib, pkgs, perSystem, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;
  inherit (perSystem.self) mkScript;

in {

  wayland.windowManager.hyprland = {

    plugins = mkIf cfg.enablePlugins [ pkgs.hyprlandPlugins.hyprexpo ];
       
    settings = {
      "plugin:hyprexpo" = {

        columns = 3;
        gap_size = 5;
        bg_col = "rgb(111111)";
        workspace_method = "first 1";

        enable_gesture = true; # laptop touchpad
        gesture_fingers = 3;  # 3 or 4
        gesture_distance = 300; # how far is the "max"
        gesture_positive = true; # positive = swipe down. Negative = swipe up.

      }; 

      bind = mkIf cfg.enablePlugins [ 
        "super, 0, hyprexpo:expo, toggle" 
      ];

      bindsn = mkIf cfg.enablePlugins [
        
        # Toggle expo with super+semicolon+apostrophe ([;'] same-time)
        "super_l, semicolon&apostrophe, hyprexpo:expo, toggle"
        "super_r, semicolon&apostrophe, hyprexpo:expo, toggle"

      ];

    };

  };

}
