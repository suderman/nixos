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
    home.packages = [pkgs.telegram-desktop];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};

    wayland.windowManager.hyprland.settings.windowrule = [
      "float, class:^(${class}|telegramdesktop)$, title:^(Media viewer)$"
    ];

    # Persist reboots, skip backups
    persist.scratch.directories = [".local/share/TelegramDesktop/tdata"];
  };
}
