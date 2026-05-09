# programs.telegram.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.telegram;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;

  # Window class name
  class = "org.telegram.desktop";
in {
  options.programs.telegram = {
    enable = lib.options.mkEnableOption "telegram";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.unstable.telegram-desktop];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};
    # Persist reboots, skip backups
    persist.scratch.directories = [".local/share/TelegramDesktop/tdata"];
    wayland.windowManager.hyprland.lua.features.telegram = ''
      hl.window_rule({
          name = "telegram-media-viewer",
          match = { class = "^(${class}|telegramdesktop)$", title = "^(Media viewer)$" },
          float = true,
      })
    '';
  };
}
