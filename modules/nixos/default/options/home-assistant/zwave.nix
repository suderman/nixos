{
  config,
  flake,
  lib,
  ...
}: let
  cfg = config.services.home-assistant;
  pin = flake.inputs.suderpkgs.pins.containers.zwave-js-ui;
  inherit (lib) mkIf;
  inherit (config.services.traefik.lib) mkLabels;
in {
  config = mkIf (cfg.enable && cfg.zwave != "") {
    # Enable reverse proxy
    services.traefik.enable = true;

    # Z-Wave JS UI container
    virtualisation.oci-containers.containers.zwave = {
      image =
        if cfg.zwaveVersion == pin.version
        then pin.image
        else "ghcr.io/zwave-js/zwave-js-ui:${cfg.zwaveVersion}";
      autoStart = false;

      # Traefik labels
      extraOptions =
        mkLabels [cfg.zwaveName 8091]
        # Networking and devices
        ++ [
          "--privileged"
          "--network=host"
        ]
        ++ [
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
        3000 # zwave websockets
        8091 # zwave web interface
      ];
    };
  };
}
