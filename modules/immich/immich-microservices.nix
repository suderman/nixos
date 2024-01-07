{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Microservices
    # https://github.com/immich-app/immich/issues/776#issuecomment-1271459885
    virtualisation.oci-containers.containers.immich-microservices = {
      image = "ghcr.io/immich-app/immich-server:v${cfg.version}";
      cmd = [ "start-microservices.sh" ];
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
        "${cfg.dataDir}/geocoding:/usr/src/app/geocoding"
      ] ++ [
        "${cfg.dataDir}:/usr/src/app/upload" 
      ] ++ (if cfg.photosDir == "" then [] else [
        "${cfg.photosDir}:/usr/src/app/upload/library" 
      ]) ++ (if cfg.externalDir == "" then [] else [
        "${cfg.externalDir}:/external:ro" 
      ]);

      # Networking for docker containers
      extraOptions = [
        "--network=immich"
        # https://github.com/immich-app/immich/blob/main/docker/hwaccel.yml
        "--device=/dev/dri:/dev/dri" 
      ];

    };

    # Extend systemd service
    systemd.services.docker-immich-microservices = {
      requires = [ "immich.service" ];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };

    };

  };

}
