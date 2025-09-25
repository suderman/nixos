{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.home-assistant;
  inherit (builtins) readFile;
  inherit (lib) mkIf;
  inherit (pkgs) writeText;
  inherit (config.services.traefik.lib) mkLabels;
in {
  config = mkIf cfg.enable {
    # Enable reverse proxy
    services.traefik.enable = true;

    # Home Assistant container
    virtualisation.oci-containers.containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:${cfg.version}";
      autoStart = false;

      # Traefik labels
      extraOptions =
        mkLabels [cfg.name 8123]
        # Networking and devices
        ++ [
          "--privileged"
          "--network=host"
        ]
        ++ (
          if cfg.zigbee == ""
          then []
          else [
            "--device=${cfg.zigbee}:/dev/zigbee"
          ]
        );

      # Environment variables
      environment = {
        TZ = config.time.timeZone;
        ISY_URL = "https://${cfg.isyName}";
        ZWAVE_URL = "https://${cfg.zwaveName}";
        HOST_IP = cfg.ip;
      };

      # Bind volume and db socket
      volumes = [
        "${cfg.dataDir}:/config"
        "/run/postgresql:/run/postgresql"
      ];
    };

    # Copy configuration yaml and ensure includes exist
    tmpfiles.files = let
      yaml = {
        mode = 775;
        user = config.users.users.hass.uid;
        group = config.users.groups.hass.gid;
      };
    in [
      (yaml // {target = "${cfg.dataDir}/automations.yaml";})
      (yaml // {target = "${cfg.dataDir}/scripts.yaml";})
      (yaml // {target = "${cfg.dataDir}/scenes.yaml";})
      (yaml
        // {
          target = "${cfg.dataDir}/configuration.yaml";
          # source = writeText "configuration.yaml" (readFile ./configuration.yaml);
          source = ./configuration.yaml;
        })
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
