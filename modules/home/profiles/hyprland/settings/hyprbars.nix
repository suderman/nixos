{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;
in {
  wayland.windowManager.hyprland = {
    # plugins = mkIf cfg.enablePlugins [ pkgs.hyprlandPlugins.hyprbars ];
    plugins = mkIf cfg.enablePlugins [perSystem.nixpkgs-unstable.hyprlandPlugins.hyprbars];

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
          (button "" 21 "hyprctl dispatch exec hypr-togglegrouporkill") # kill
          (button "󰽤" 18 "hyprctl dispatch exec hypr-togglegrouporlockornavigate") # group
          (button "󰔷" 19 "hyprctl dispatch exec hypr-togglefullscreenorspecial") # max/min
          (button "" 18 "hyprctl dispatch exec hypr-togglefloatingorsplit") # window
        ];
      };

      # Hide bars when floating windows are unfocussed
      windowrulev2 = [
        "plugin:hyprbars:nobar, floating:0" # disable hyprbars for tiling windows
        "plugin:hyprbars:nobar, floating:1, focus:0 " # disable hyprbars for unfocussed floating windows
      ];

      bind = [
        # Kill the group or window
        "super, q, exec, hypr-togglegrouporkill"

        # Toggle floating or tiled windows
        "super, slash, exec, hypr-togglefloatingorsplit left" # toggle floating/tiled
        "super+shift, f, exec, hypr-togglefloatingorsplit left"
        "super+alt, slash, exec, hypr-togglefloatingorsplit right" # toggle pin/split

        # Prev window in group with super+comma [<]
        "super, comma, changegroupactive, b"
        "super, comma, lockactivegroup, lock"

        # Next window in group with super+period [>]
        "super, period, changegroupactive, f"
        "super, period, lockactivegroup, lock"

        # Fullscreen toggle
        "super, f, exec, hypr-togglefullscreenorspecial left" # fullscreen 1 (focus)
        "super+alt, f, exec, hypr-togglefullscreenorspecial middle" # fullscreen 0 (full)

        # Minimize windows (send to special workspace) and restore
        "super+alt, escape, exec, hypr-togglefullscreenorspecial right" # movetoworkspacesilent special

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
}
