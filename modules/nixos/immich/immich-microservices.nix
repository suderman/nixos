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
      entrypoint = "/bin/sh";
      cmd = [ "./start-microservices.sh" ];
      autoStart = false;

      # Run as immich user
      user = "${cfg.environment.PUID}:${cfg.environment.PGID}";

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Map volumes to host
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload" 
        "${cfg.dataDir}/geocoding:/usr/src/app/geocoding"
      ];

      # Networking for docker containers
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--network=immich"
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