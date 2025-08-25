# programs.slack.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.slack;
  inherit (lib) mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "slack";
in {
  options.programs.slack = {
    enable = lib.options.mkEnableOption "slack";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.slack];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};

    wayland.windowManager.hyprland.settings = {
      windowrule = [];
    };

    # Persist reboots, skip backups
    impermanence.scratch.directories = [".config/Slack"];
  };
}
