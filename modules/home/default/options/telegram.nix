# programs.telegram.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.telegram;
  inherit (lib) mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "org.telegram.desktop";
in {
  options.programs.telegram = {
    enable = lib.options.mkEnableOption "telegram";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.tdesktop];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};

    wayland.windowManager.hyprland.settings = {
      windowrule = [];
    };

    # Persist reboots, skip backups
    persist.scratch.directories = [".local/share/TelegramDesktop/tdata"];
  };
}
