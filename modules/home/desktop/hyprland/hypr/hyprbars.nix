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
    enable = lib.mkEnableOption "Hyprbars titlebars";

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

  config = mkIf cfg.hyprbars.enable {
    wayland.windowManager.hyprland.lua.features.hyprbars =
      # lua
      ''
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
                -- lib/appearance.lua sets bar_color and col.text.
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
