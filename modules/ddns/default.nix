# modules.ddns.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.ddns;
  secrets = config.age.secrets;
  inherit (lib) mkIf;

in {

  options.modules.ddns = {
    enable = lib.options.mkEnableOption "ddns"; 
  };

  config = mkIf cfg.enable {

    # Create DNS record of this machine's public IP
    # ddns.mymachine.mydomain.org -> 184.65.200.230 
    systemd.services."ddns" = {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = secrets.cloudflare-env.path;
      };
      environment = with config.networking; {
        HOSTNAME = hostName;
        DOMAIN = domain;
      };
      path = with pkgs; [ coreutils curl dig gawk jq ];
      script = builtins.readFile ./ddns.sh;
    };

    # Run this script every 15 minutes
    systemd.timers."ddns" = {
      wantedBy = [ "timers.target" ];
      partOf = [ "ddns.service" ];
      timerConfig = {
        OnCalendar = "*:0/15";
        Unit = "ddns.service";
      };
    };

  };

}
