{
  config,
  flake,
  lib,
  ...
}: let
  cfg = config.services.home-assistant;
  inherit (lib) mkIf optional;
  inherit (config.services.traefik.lib) mkLabels;
in {
  config = mkIf cfg.enable {
    # Enable reverse proxy
    services.traefik.enable = true;

    # Home Assistant container
    virtualisation.oci-containers.containers.home-assistant = let
      pin = flake.inputs.pins.default.containers.home-assistant;
    in {
      image =
        if cfg.version == pin.version
        then pin.image
        else "ghcr.io/home-assistant/home-assistant:${cfg.version}";
      devices = optional (cfg.zigbee != "") "${cfg.zigbee}:/dev/zigbee";

      # Traefik labels and networking
      extraOptions = mkLabels [cfg.name 8123] ++ ["--network=host"];

      # Environment variables
      environment = {
        TZ = config.time.timeZone;
        HOST_IP = cfg.ip;
      };

      # Bind volume, read-only configuration, and db socket
      volumes = [
        "${cfg.dataDir}:/config"
        "${./configuration.yaml}:/config/configuration.yaml:ro"
        "/run/postgresql:/run/postgresql"
      ];
    };

    # The recorder connects through the postgres socket
    systemd.services.docker-home-assistant = {
      after = ["postgresql.service"];
      wants = ["postgresql.service"];
    };

    # Ensure includes exist
    tmpfiles.files = let
      yaml = {
        mode = 660;
        user = config.users.users.hass.uid;
        group = config.users.groups.hass.gid;
      };
    in [
      (yaml // {target = "${cfg.dataDir}/automations.yaml";})
      (yaml // {target = "${cfg.dataDir}/scripts.yaml";})
      (yaml // {target = "${cfg.dataDir}/scenes.yaml";})
    ];

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [
        8123 # home-assistant
        21063 # homekit
      ];
    };
  };
}
