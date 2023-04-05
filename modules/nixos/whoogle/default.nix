# services.whoogle.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 

  cfg = config.services.whoogle;
  host = "search.${config.networking.fqdn}";

  inherit (lib) mkIf mkForce;
  inherit (lib.options) mkEnableOption;

in {
  options = {
    services.whoogle.enable = mkEnableOption "whoogle"; 
  };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.containers."whoogle" = {
      image = "benbusby/whoogle-search";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoogle.rule=Host(`${host}`)"
        "--label=traefik.http.routers.whoogle.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.whoogle.middlewares=local@file"
      ];
    };

    # Container will not stop gracefully, so kill it
    systemd.services.docker-whoogle.serviceConfig = {
      KillSignal = "SIGKILL";
      SuccessExitStatus = "0 SIGKILL";
    };

  }; 

}
