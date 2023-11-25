{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Server back-end
    virtualisation.oci-containers.containers.immich-server = {
      image = "ghcr.io/immich-app/immich-server:v${cfg.version}";
      cmd = [ "start-server.sh" ];
      autoStart = false;

      # Run as immich user
      user = "${cfg.environment.PUID}:${cfg.environment.PGID}";

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Map volumes to host
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload"
      ] ++ (if cfg.photosDir == "" then [] else [
        "${cfg.photosDir}:/usr/src/app/upload/library" 
      ]);

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
    systemd.services.docker-immich-server = {
      requires = [ "immich.service" ];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };

    };

  };

}
