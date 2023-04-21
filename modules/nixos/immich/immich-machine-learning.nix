{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:v${cfg.version}";
      autoStart = false;

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Map volumes to host
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload" 
        "immich-machine-learning:/cache"
      ];

      # Networking for docker containers
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--network=immich"
      ];

    };

    # Extend systemd service
    systemd.services.docker-immich-machine-learning = {
      requires = [ "immich.service" ];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };
    };

  };

}