# programs.telegram.enable = true;
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.programs.telegram;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;

  # Window class name
  class = "org.telegram.desktop";
  hasHyprLua = lib.hasAttrByPath ["wayland" "windowManager" "hyprland" "lua" "features"] options;
in {
  options.programs.telegram = {
    enable = lib.options.mkEnableOption "telegram";
  };

  config = mkIf cfg.enable (lib.mkMerge [
    {
    home.packages = [pkgs.unstable.telegram-desktop];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};

    wayland.windowManager.hyprland.settings.windowrule = [
      "float on, match:class ^(${class}|telegramdesktop)$, match:title ^(Media viewer)$"
    ];

    # Persist reboots, skip backups
    persist.scratch.directories = [".local/share/TelegramDesktop/tdata"];
    }
    (lib.optionalAttrs hasHyprLua {
      wayland.windowManager.hyprland.lua.features.telegram = ''
        hl.window_rule({
            name = "telegram-media-viewer",
            match = { class = "^(${class}|telegramdesktop)$", title = "^(Media viewer)$" },
            float = true,
        })
      '';
    })
  ]);
}
