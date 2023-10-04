# modules.whoogle.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 

  cfg = config.modules.whoogle;
  inherit (lib) mkIf mkOption mkBefore types;

in {

  options.modules.whoogle = {

    enable = lib.options.mkEnableOption "whoogle"; 

    hostName = mkOption {
      type = types.str;
      default = "whoogle.${config.networking.fqdn}";
      description = "FQDN for the Whoogle instance";
    };

  };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.containers."whoogle" = {
      image = "benbusby/whoogle-search";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoogle.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.whoogle.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.whoogle.middlewares=local@file"
      ];
    };

    # Container will not stop gracefully, so kill it
    systemd.services.docker-whoogle.serviceConfig = {
      KillSignal = "SIGKILL";
      SuccessExitStatus = "0 SIGKILL";
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

  }; 

}
