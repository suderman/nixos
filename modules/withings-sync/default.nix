# modules.withings-sync.enable = true;

# Manually sync today:
# withings-sync
#
# Force a date further back to sync from:
# withings-sync -f 2023-09-21
#
# Check the timer for the next run
# systemctl list-timers --all 

{ inputs, config, pkgs, lib, this, ... }:
  
let 

  cfg = config.modules.withings-sync;
  user = builtins.head this.admins;
  inherit (config.age) secrets;
  inherit (lib) mkIf mkForce;

  # https://github.com/jaroslawhartman/withings-sync/releases/tag/v3.6.1
  img = "ghcr.io/jaroslawhartman/withings-sync:master";
  flags = ''--name withings --rm -e GARMIN_USERNAME -e GARMIN_PASSWORD -v "/home/${user}:/root"''; 

in {

  options.modules.withings-sync = {
    enable = lib.options.mkEnableOption "withings-sync"; 
  };

  config = mkIf cfg.enable {

    # Create shell script wrapper for docker run
    environment.systemPackages = let script = ''
      source "${secrets.withings-env.path}"
      export GARMIN_USERNAME GARMIN_PASSWORD
      if [[ -v NONINTERACTIVE ]]; then
        docker run ${flags} ${img} "$@"
      else
        docker run -it ${flags} ${img} "$@"
      fi
    ''; in [( pkgs.writeShellScriptBin "withings-sync" script )];

    # Create systemd service and timer
    systemd.services.withings-sync = {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = secrets.withings-env.path; 
      };
      environment = {
        NONINTERACTIVE = "1";
      };
      path = with pkgs; [ docker ];
      script = "/run/current-system/sw/bin/withings-sync";
    };

    # Run this script every two hours
    systemd.timers.withings-sync = {
      wantedBy = [ "timers.target" ];
      partOf = [ "withings-sync.service" ];
      timerConfig = {
        OnCalendar = "0/1:00";
        Unit = "withings-sync.service";
      };
    };

    # Allow user to read withings-env file
    age.secrets.withings-env.owner = mkForce user;

  }; 

}
