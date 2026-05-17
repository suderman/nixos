{
  config,
  lib,
  perSystem,
  ...
}:
let
  cfg = config.wayland.windowManager.hyprland;
  hyprbars = "${perSystem.hyprland-plugins.hyprbars}/lib/libhyprbars.so";
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enableOfficialPlugins {
    wayland.windowManager.hyprland.lua.features.hyprbars =
      # lua
      ''
        local stylix = require("generated.stylix")

        local function button(icon, size, command)
          hyprbars.add_button({
            bg_color = "rgba(00000000)",
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
                bar_blur = true,
                bar_button_padding = 4,
                bar_color = stylix.base00.rgba(0.8),
                ["col.text"] = stylix.base05.rgba(0.8),
                bar_height = 25,
                bar_padding = 10,
                bar_part_of_window = false,
                bar_precedence_over_border = false,
                bar_text_font = "sanserif",
                bar_text_size = 11,
                bar_title_enabled = true,
                icon_on_hover = true,
                on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
              },
            },
          })

          button("", 20, "hypr-togglegrouporkill")
          button("󰽤", 17, "hypr-togglegrouporlock")
          button("", 17, "hypr-togglefloating")
        end

        local function load_and_configure_hyprbars()
          hl.exec_cmd("hyprctl plugin load ${hyprbars}")
          hl.timer(configure_hyprbars, { timeout = 500, type = "oneshot" })
        end

        if hyprbars and hyprbars.add_button then
          configure_hyprbars()
        else
          hl.on("hyprland.start", load_and_configure_hyprbars)
        end

        util.exec("ESCAPE", "hypr-toggletitlebars", { non_consuming = true })
        util.exec("SUPER + SLASH", "hypr-toggletitlebars", { non_consuming = true })
      '';
  };
}
