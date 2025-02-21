# services.withing-sync.enable = true;
#
# Manually sync today:
# withings-sync
#
# Force a date further back to sync from:
# withings-sync -f 2025-01-01
#
# Check the timer for the next run
# systemctl list-timers --all 
#
{ config, lib, pkgs, ... }: let

  cfg = config.services.withings-sync;
  inherit (lib) getExe mkIf mkShellScript;

  # Access secret with login credentials
  age.secrets.withings-env.file = config.secrets.files.withings-env;

  withings-sync-wrapped = mkShellScript { 
    name = "withings-sync"; 
    text = ''
      source ${config.age.secrets.withings-env.path}
      export GARMIN_USERNAME
      export GARMIN_PASSWORD
      export PYTHONPATH=${pkgs.python312Packages.setuptools}/lib/python3.12/site-packages:${pkgs.python312}/lib/python3.12/site-packages
      ${getExe pkgs.python312Packages.withings-sync} ''${@-}
    '';
    };

in {

  options.services.withings-sync = {
    enable = lib.options.mkEnableOption "withings-sync"; 
  };

  config = mkIf cfg.enable {

    # Add to path for initial setup and on-demand
    home.packages = [ withings-sync-wrapped ]; 

    # Run this command every couple of hours
    systemd.user = let
      desc = "Sync Withings weight data with Garmin Connect";
    in {

      services.withings-sync = {
        Unit.Description = desc;
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "oneshot";
          ExecStart = getExe withings-sync-wrapped;
        };
      };

      timers.withings-sync = {
        Unit.Description = desc;
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnCalendar = "*-*-* 0/2:00:00";  # Every 2 hours
          Persistent = true;
        };
      };

    };

  };

}
