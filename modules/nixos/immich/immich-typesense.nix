{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Typesense search engine
    virtualisation.oci-containers.containers.immich-typesense = {
      # image = "typesense/typesense:0.24.1";
      image = "typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd";
      autoStart = false;

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Map volumes to host
      volumes = [ "immich-typesense:/data" ];

      # Networking for docker containers
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--network=immich"
        # "--cpus=0.9"
      ];

    };

    # Extend systemd service
    systemd.services.docker-immich-typesense = {
      requires = [ "immich.service" ];
    };

  };

}
