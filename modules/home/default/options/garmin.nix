# services.garmin.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.services.garmin;
  inherit (lib) mkIf mkOption types;
  runDir = "/run/user/${toString config.home.uid}/gvfs/mtp:host=${cfg.deviceId}/Primary";
in {
  options.services.garmin = {
    enable = lib.options.mkEnableOption "garmin";
    deviceId = mkOption {
      type = types.str;
      default = "";
      example = "091e_4cda_0000cb7d522d";
    };
    dataDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Garmin";
    };
  };

  config = mkIf cfg.enable {
    systemd.user = {
      services.garmin = {
        Unit = {
          Description = "Sync Garmin";
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${
            perSystem.self.mkScript {
              path = [pkgs.glib];
              text =
                # bash
                ''
                  # Push audio files
                  gio copy -r -p ${cfg.dataDir} "${runDir}/Audio"

                  # Pull FIT files
                  gio copy -r -p "${runDir}/GARMIN/Activity" ${cfg.dataDir}/Activity
                '';
            }
          }";
          Restart = "no";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };

      # Watch persistent storage for updates
      paths.garmin = {
        Unit.Description = "Sync Garmin";
        Path = {
          PathExists = runDir;
          Unit = "garmin.service";
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
