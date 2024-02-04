{ config, lib, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (builtins) toString;
  inherit (lib) mkIf mkBefore;
  inherit (config.modules) traefik;

in {

  config = mkIf (cfg.enable && cfg.zwave != "") {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Z-Wave JS UI container
    virtualisation.oci-containers.containers.zwave = {
      image = "ghcr.io/zwave-js/zwave-js-ui:${cfg.zwaveVersion}";
      autoStart = false;

      # Traefik labels
      extraOptions = traefik.labels [ cfg.zwaveName 8091 ]

      # Networking and devices
      ++ [ "--privileged"
        "--network=host"
      ] ++ [
        "--device=${cfg.zwave}:/dev/zwave"
        "--stop-signal=SIGINT"
        "-t"
      ];

      # Environment variables
      environment = {
        TZ = config.time.timeZone;
      };

      # Bind volume
      volumes = [ 
        "${cfg.dataDir}/zwave:/usr/src/app/store"
      ];

    };

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [ 
        3000  # zwave websockets
        8091  # zwave web interface 
      ];
    };

  };

}
