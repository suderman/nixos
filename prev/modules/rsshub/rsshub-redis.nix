{ config, lib, pkgs, ... }: let

  cfg = config.services.rsshub;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Redis cache
    virtualisation.oci-containers.containers.rsshub-redis = {
      image = "redis:6.2";
      autoStart = false;

      # Map volumes to host
      volumes = [ "rsshub-redis:/data" ];

      # Networking for docker containers
      extraOptions = [
        "--network=rsshub"
      ];

    };

    # Extend systemd service
    systemd.services.docker-rsshub-redis = {
      requires = [ "rsshub.service" ];
    };

  };

}
