{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (builtins) toString;
  inherit (lib) mkIf mkShellScript;

in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {

      plugins = [ pkgs.hyprlandPlugins.hyprbars ];

      settings = {
        "plugin:hyprbars" = {

          bar_height = 30; 
          bar_padding = 10;
          bar_button_padding = 5; 
          bar_color = "rgba(151521d9)";

          bar_part_of_window = false;
          bar_precedence_over_border = false; 
          bar_title_enabled = true;

          # https://gist.github.com/lopspower/03fb1cc0ac9f32ef38f4
          hyprbars-button = let 
            button = icon: size: command: "rgba(15152100), ${toString size}, ${icon}, ${command}"; 
          in [
            ( button "" 21 "hyprctl dispatch exec hypr-togglegrouporkill" ) # kill
            ( button "󰽤" 18 "hyprctl dispatch exec hypr-togglegrouporlockornavigate" ) # group
            ( button "󰔷" 19 "hyprctl dispatch exec hypr-togglefullscreenorspecial" ) # max/min
            ( button "" 18 "hyprctl dispatch exec hypr-togglefloatingorsplit" ) # window
          ];

        }; 

        # Hide bars when floating windows are unfocussed
        windowrulev2 = [ "plugin:hyprbars:nobar, focus:0, floating:1" ];

        bind = [

          # Kill the group or window
          "super, q, exec, hypr-togglegrouporkill"

          # Toggle floating or tiled windows
          "alt, space, exec, hypr-togglefloatingorsplit"

          # Prev window in group with super+comma [<]
          "super, comma, changegroupactive, b"
          "super, comma, lockactivegroup, lock"

          # Next window in group with super+period [>]
          "super, period, changegroupactive, f" 
          "super, period, lockactivegroup, lock"

          # Fullscreen toggle
          "alt, z, exec, hypr-togglefullscreenorspecial left" # fullscreen 1 (zoom window)
          "shift+alt, z, exec, hypr-togglefullscreenorspecial middle" # fullscreen 0 (no waybar)
          "alt, return, exec, hypr-togglefullscreenorspecial middle" 

          # Minimize windows (send to special workspace) and restore
          "alt, escape, exec, hypr-togglefullscreenorspecial right" # movetoworkspacesilent special
          "super+alt, escape, exec, hypr-togglefullscreenorspecial right"

          # toggle special workspace
          "super, escape, togglespecialworkspace" 

        ];

        bindsn = [
          
          # Toggle group lock with super+comma+period ([<>] same-time)
          "super_l, comma&period, exec, hypr-togglegrouporlockornavigate right"
          "super_r, comma&period, exec, hypr-togglegrouporlockornavigate right"

        ];

      };

    };
  };

}
