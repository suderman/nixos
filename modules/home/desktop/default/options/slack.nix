# programs.slack.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.slack;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;

  # Window class name
  class = "slack";
in {
  options.programs.slack = {
    enable = lib.options.mkEnableOption "slack";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.slack.overrideAttrs (old: {
        # Temporary UTC-6 workaround until Slack updates its Edmonton timezone rules.
        postFixup =
          (old.postFixup or "")
          + ''
            wrapProgram "$out/bin/slack" --set TZ America/Regina
          '';
      }))
    ];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};
    # Persist reboots, skip backups
    persist.scratch.directories = [".config/Slack"];
  };
}
