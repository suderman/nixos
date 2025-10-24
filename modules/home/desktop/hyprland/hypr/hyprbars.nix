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
      "plugin:hyprbars" = with config.lib.stylix.colors; {
        bar_blur = true;
        bar_button_padding = 4;
        bar_color = "rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b},0.8)";
        "col.text" = "rgba(${base05-rgb-r},${base05-rgb-g},${base05-rgb-b},0.8)";
        bar_height = 25;
        bar_padding = 10;
        bar_part_of_window = false;
        bar_precedence_over_border = false;
        bar_text_font = "sanserif";
        bar_text_size = 11;
        bar_title_enabled = true;
        icon_on_hover = true;

        # https://gist.github.com/lopspower/03fb1cc0ac9f32ef38f4
        hyprbars-button = let
          button = icon: size: command: "rgba(00000000), ${toString size}, ${icon}, ${command}";
        in [
          (button "" 20 "hyprctl dispatch exec hypr-togglegrouporkill") # kill
          (button "󰽤" 17 "hyprctl dispatch exec hypr-togglegrouporlock") # group
          # (button "󰔷" 18 "hyprctl dispatch exec hypr-togglespecial") # special
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
