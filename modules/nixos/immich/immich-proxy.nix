{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Reverse proxy server
    virtualisation.oci-containers.containers.immich-proxy = {
      image = "ghcr.io/immich-app/immich-proxy:v${cfg.version}";
      autoStart = false;

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.immich.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.immich.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.immich.middlewares=local@file"

      # Networking for docker containers
      ] ++ [
        "--add-host=host.docker.internal:host-gateway"
        "--network=immich"
      ];

    };

    # Extend systemd service
    systemd.services.docker-immich-proxy = {
      requires = [ "immich.service" ];
    };

  };

}
