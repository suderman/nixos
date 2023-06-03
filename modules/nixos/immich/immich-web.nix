{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf mkBefore;

in {

  config = mkIf cfg.enable {

    # Web front-end
    virtualisation.oci-containers.containers.immich-web = {
      image = "ghcr.io/immich-app/immich-web:v${cfg.version}";
      # entrypoint = "/bin/sh";
      # cmd = [ "./entrypoint.sh" ];
      autoStart = false;

      # Environment variables
      environment = cfg.environment;
      environmentFiles =  [ cfg.environment.file ];

      # Networking for docker containers
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--network=immich"
      ];

    };
      
    # Extend systemd service
    systemd.services.docker-immich-web = {
      requires = [ "immich.service" ];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };

    };

  };

}
