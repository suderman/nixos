# modules.withings-sync.enable = true;
{ inputs, config, pkgs, lib, user, ... }:
  
let 

  cfg = config.modules.withings-sync;
  secrets = config.age.secrets;
  inherit (lib) mkIf;

  # https://github.com/jaroslawhartman/withings-sync/
  docker = "${pkgs.docker}/bin/docker";
  flags = ''--name withings --rm -e GARMIN_USERNAME -e GARMIN_PASSWORD -v "$HOME:/root"''; 

  # https://github.com/jaroslawhartman/withings-sync/releases/tag/v3.6.1
  img = "ghcr.io/jaroslawhartman/withings-sync:master";

in {

  options.modules.withings-sync = {
    enable = lib.options.mkEnableOption "withings-sync"; 
  };

  config = mkIf cfg.enable {

    # Create shell script wrapper for docker run
    environment.systemPackages = let script = ''
      if [[ -v NONINTERACTIVE ]]; then
        ${docker} run ${flags} ${img} "$@"
      else
        ${docker} run -it ${flags} ${img} "$@"
      fi
    ''; in [( pkgs.writeShellScriptBin "withings-sync" script )];

    # Create systemd service and timer
    systemd = {

      # Run noninteractively
      services.withings-sync = {
        enable = true;
        description = "Run withings sync";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          EnvironmentFile = secrets.withings-env.path; 
          User = "${user}";
        };
        environment.NONINTERACTIVE = "1";
        script = "/run/current-system/sw/bin/withings-sync";
      };

      # Run every 3 hours
      timers.withings-sync = {
        wantedBy = [ "timers.target" ];
        partOf = [ "withings-sync.service" ];
        timerConfig = {
          OnCalendar = "*:0/3";
          Unit = "withings-sync.service";
        };
      };

    };


  }; 

}
