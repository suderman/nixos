{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;
  inherit (config.modules) traefik;

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

      # Map volumes to host
      volumes = [ 
        "/run/postgresql:/run/postgresql"
        "/run/redis-immich:/run/redis-immich"
      ] ++ [
        "${cfg.dataDir}:/usr/src/app/upload"
      ] ++ (if cfg.photosDir == "" then [] else [
        "${cfg.photosDir}:/usr/src/app/upload/library" 
      ]) ++ (if cfg.externalDir == "" then [] else [
        "${cfg.externalDir}:/external:ro" 
      ]);

      # Traefik labels
      extraOptions = traefik.labels cfg.name

      # Networking for docker containers
      ++ [ "--network=immich" ];

    };

    # Enable reverse proxy
    modules.traefik = {
      enable = true;
      routers = traefik.alias cfg.name cfg.alias;
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
