{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;
in {
  wayland.windowManager.hyprland = {
    # plugins = mkIf cfg.enablePlugins [ pkgs.hyprlandPlugins.hyprbars ];
    plugins = mkIf cfg.enablePlugins [pkgs.unstable.hyprlandPlugins.hyprbars];

    settings = {
      "plugin:hyprbars" = {
        bar_blur = true;
        bar_button_padding = 4;
        bar_color = "rgba(21,21,33,0.85)";
        "col.text" = "rgba(183,189,248,0.9)";
        bar_height = 20;
        bar_padding = 10;
        bar_part_of_window = false;
        bar_precedence_over_border = false;
        bar_text_font = "monospace";
        bar_text_size = "10";
        bar_title_enabled = true;
        icon_on_hover = true;

        # https://gist.github.com/lopspower/03fb1cc0ac9f32ef38f4
        hyprbars-button = let
          button = icon: size: command: "rgba(00000000), ${toString size}, ${icon}, ${command}";
        in [
          (button "" 20 "hyprctl dispatch exec hypr-togglegrouporkill") # kill
          (button "󰽤" 17 "hyprctl dispatch exec hypr-togglegrouporlockornavigate") # group
          (button "󰔷" 18 "hyprctl dispatch exec hypr-togglefullscreenorspecial") # max/min
          (button "" 17 "hyprctl dispatch exec hypr-togglefloatingorsplit") # window
        ];
      };

      # Hide bars when floating windows are unfocussed
      windowrule = [
        # "plugin:hyprbars:nobar, floating:0" # disable hyprbars for tiling windows
        # "plugin:hyprbars:nobar, floating:1, focus:0 " # disable hyprbars for unfocussed floating windows
      ];

      bind = [
        # Kill the group or window
        "super, q, exec, hypr-togglegrouporkill"

        # Toggle floating or tiled windows
        "super, slash, exec, hypr-togglefloatingorsplit left" # toggle floating/tiled
        "super+shift, f, exec, hypr-togglefloatingorsplit left"
        "super+alt, slash, exec, hypr-togglefloatingorsplit right" # toggle pin/split

        # Prev window in group with super+comma [<]
        # "super, comma, changegroupactive, b"
        # "super, comma, lockactivegroup, lock"
        "super, comma, exec, hypr-togglegrouporlockornavigate prev"

        # Next window in group with super+period [>]
        # "super, period, changegroupactive, f"
        # "super, period, lockactivegroup, lock"
        "super, period, exec, hypr-togglegrouporlockornavigate next"

        # Fullscreen toggle
        "super, f, exec, hypr-togglefullscreenorspecial left" # fullscreen 1 (focus)
        "super+alt, f, exec, hypr-togglefullscreenorspecial middle" # fullscreen 0 (full)

        # Minimize windows (send to special workspace) and restore
        "super+alt, escape, exec, hypr-togglefullscreenorspecial right" # movetoworkspacesilent special

        # toggle special workspace
        "super, escape, togglespecialworkspace"

        # Toggle group lock with super+alt click
        "super+alt, mouse:272, exec, hypr-togglegrouporlockornavigate"

        "super, y, exec, hypr-toggletitlebars"
      ];

      # Toggle group lock with long press Escape
      bindo = [", Escape, exec, hypr-togglegrouporlockornavigate"];

      bindsn = [
        # Toggle group lock with super+comma+period ([<>] same-time)
        "super_l, comma&period, exec, hypr-togglegrouporlockornavigate"
        "super_r, comma&period, exec, hypr-togglegrouporlockornavigate"
      ];
    };
  };
}
