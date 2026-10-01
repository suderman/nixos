{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
  hyprbars = "${perSystem.hyprland-plugins.hyprbars}/lib/libhyprbars.so";
  inherit (builtins) toJSON;
  inherit (lib) mkIf mkOption types;
in {
  options.wayland.windowManager.hyprland.hyprbars = {
    barBlur = mkOption {
      type = types.bool;
      default = true;
      description = "Whether hyprbars titlebars use blur.";
    };

    barPrecedenceOverBorder = mkOption {
      type = types.bool;
      default = false;
      description = "Whether hyprbars titlebars render above window borders.";
    };
  };

  config = mkIf cfg.enableOfficialPlugins {
    wayland.windowManager.hyprland.lua.features.hyprbars =
      # lua
      ''
        local stylix = require("generated.stylix")
        hl.plugin.load(${toJSON hyprbars})
        local hyprbars = hl.plugin.hyprbars

        local function button(icon, size, command)
          hyprbars.add_button({
            -- Button colors are fixed by the plugin API. A dark neutral fill
            -- keeps white hover glyphs readable in both appearance modes.
            bg_color = "rgb(313244)",
            fg_color = "rgb(ffffff)",
            size = size,
            icon = icon,
            action = command,
          })
        end

        local function configure_hyprbars()
          hl.config({
            plugin = {
              hyprbars = {
                enabled = true,
                bar_blur = ${toJSON cfg.hyprbars.barBlur},
                bar_button_padding = 4,
                bar_color = stylix.base00.rgba(0.8),
                ["col.text"] = stylix.base05.rgba(0.8),
                bar_height = 25,
                bar_padding = 10,
                bar_part_of_window = false,
                bar_precedence_over_border = ${toJSON cfg.hyprbars.barPrecedenceOverBorder},
                bar_text_font = "sanserif",
                bar_text_size = 11,
                bar_title_enabled = true,
                icon_on_hover = true,
                on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
              },
            },
          })

          button("", 20, "hypr-togglegrouporclose")
          button("󰽤", 17, "hypr-togglegrouporlock")
          button("", 17, "hypr-togglefloating")
        end

        if hyprbars and hyprbars.add_button then
          configure_hyprbars()
        end

        util.exec("ESCAPE", "hypr-toggletitlebars", { non_consuming = true, long_press = true })
      '';
  };
}
