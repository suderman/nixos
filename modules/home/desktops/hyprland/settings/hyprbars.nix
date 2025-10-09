{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;
in {
  wayland.windowManager.hyprland = mkIf cfg.enablePlugins {
    plugins = [pkgs.unstable.hyprlandPlugins.hyprbars];

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
          (button "󰽤" 17 "hyprctl dispatch exec hypr-togglegrouporlock") # group
          (button "󰔷" 18 "hyprctl dispatch exec hypr-togglespecial") # special
          (button "" 17 "hyprctl dispatch exec hypr-togglefloating") # window
        ];

        on_double_click = "hyprctl dispatch fullscreen 1"; # fullscreen
      };

      bindo = [
        ", Escape, exec, hypr-toggletitlebars"
        "super, slash, exec, hypr-toggletitlebars"
      ];
    };
  };
}
