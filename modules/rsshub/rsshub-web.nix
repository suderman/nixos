{ config, lib, pkgs, ... }:

let

  cfg = config.modules.rsshub;
  inherit (lib) mkIf mkBefore;

in {

  config = mkIf cfg.enable {

    # Web front-end
    virtualisation.oci-containers.containers.rsshub-web = {
      image = "diygod/rsshub:${cfg.tag}";
      autoStart = false;

      # Environment variables
      environment = {
        NODE_ENV = "production";
        CACHE_TYPE = "redis";
        REDIS_URL = "redis://redis:6379/";
      };

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.rsshub.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.rsshub.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.rsshub.middlewares=local@file"

      # Networking for docker containers
      ] ++ [
        "--network=rsshub"
      ];

    };
      
    # Extend systemd service
    systemd.services.docker-rsshub-web = {
      requires = [ "rsshub.service" ];

      # # Container will not stop gracefully, so kill it
      # serviceConfig = {
      #   KillSignal = "SIGKILL";
      #   SuccessExitStatus = "0 SIGKILL";
      # };

    };

  };

}
