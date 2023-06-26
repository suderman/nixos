{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Typesense search engine
    virtualisation.oci-containers.containers.immich-typesense = {
      image = "typesense/typesense:0.24.1";
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
        "--cpus=0.9"
      ];

    };

    # Extend systemd service
    systemd.services.docker-immich-typesense = {
      requires = [ "immich.service" ];
    };

  };

}
