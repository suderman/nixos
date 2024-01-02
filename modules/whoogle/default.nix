# modules.whoogle.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 

  # https://github.com/benbusby/whoogle-search/releases
  version = "0.8.4";

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

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers."whoogle" = {
      image = "benbusby/whoogle-search:${version}";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.whoogle.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.whoogle.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.whoogle.middlewares=local@file"
      ];
    };

    # Extend systemd service
    systemd.services.docker-whoogle = {
      after = [ "traefik.service" ];
      requires = [ "traefik.service" ];
      preStart = with config.virtualisation.oci-containers.containers; ''
        docker pull ${whoogle.image};
      '';
      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };
    };

  }; 

}
