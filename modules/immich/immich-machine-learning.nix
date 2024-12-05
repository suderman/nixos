{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (lib) mkIf;
  port = 3333; # machine learning port

in {

  config = mkIf cfg.enable {

    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = let
      version = if cfg.cuda then "${cfg.version}-cuda" else cfg.version; 
    in {
      image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
      autoStart = false;

      # Environment variables
      environment = cfg.environment;

      # Map volumes to host
      volumes = [ 
        "immich-machine-learning:/cache"
      ];

      # Make ML available on network 
      ports = [ "${toString port}:3003" ];

      # Networking for docker containers
      extraOptions = [ 
        "--network=immich"
      ] ++ ( if cfg.cuda then [ "--device=nvidia.com/gpu=all" ] else [] ); # use nvidia gpu if present

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

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [ port ];
    };

  };

}
