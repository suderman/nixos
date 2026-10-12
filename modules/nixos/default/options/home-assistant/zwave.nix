{
  config,
  flake,
  lib,
  ...
}: let
  cfg = config.services.home-assistant;
  inherit (lib) mkIf;
  inherit (config.services.traefik.lib) mkLabels;
in {
  config = mkIf (cfg.enable && cfg.zwave != "") {
    # Enable reverse proxy
    services.traefik.enable = true;

    # Z-Wave JS UI container
    virtualisation.oci-containers.containers.zwave = let
      pin = flake.inputs.pins.default.containers.zwave-js-ui;
    in {
      image =
        if cfg.zwaveVersion == pin.version
        then pin.image
        else "ghcr.io/zwave-js/zwave-js-ui:${cfg.zwaveVersion}";
      devices = ["${cfg.zwave}:/dev/zwave"];

      # Traefik labels and networking
      extraOptions =
        mkLabels [cfg.zwaveName 8091]
        ++ [
          "--network=host"
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

    # No firewall ports: Home Assistant reaches the websocket server (3000) on
    # localhost, and the web interface (8091) is served through Traefik.
  };
}
