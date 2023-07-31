{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Redis cache
    virtualisation.oci-containers.containers.immich-redis = {
      # image = "redis:6.2";
      image = "redis:6.2-alpine@sha256:70a7a5b641117670beae0d80658430853896b5ef269ccf00d1827427e3263fa3";
      autoStart = false;

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Map volumes to host
      volumes = [ "immich-redis:/data" ];

      # Networking for docker containers
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--network=immich"
      ];

    };

    # Extend systemd service
    systemd.services.docker-immich-redis = {
      requires = [ "immich.service" ];
    };

  };

}
