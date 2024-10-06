{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  inherit (lib) mkIf;
  nvidia = if config.hardware.nvidia.modesetting.enable then "-cuda" else ""; # set if using nvidia
  port = 3333; # machine learning port

in {

  config = mkIf cfg.enable {

    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:v${cfg.version}${nvidia}";
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
      ] ++ ( if nvidia == "" then [] else [ "--device=nvidia.com/gpu=all" ] ); # use nvidia gpu if present

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
