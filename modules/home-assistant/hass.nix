{ config, lib, pkgs, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString readFile;
  inherit (pkgs) writeText;

in {

  config = mkIf cfg.enable {

    # Home Assistant container
    virtualisation.oci-containers.containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:${cfg.version}";
      autoStart = false;

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.hass.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.hass.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.hass.middlewares=local@file"
        "--label=traefik.http.services.hass.loadbalancer.server.port=8123"
        "--label=traefik.http.services.hass.loadbalancer.server.scheme=http"

      # Networking and devices
      ] ++ [
        "--privileged" 
        "--network=host"
      ] ++ (if cfg.zigbee == "" then [] else [
        "--device=${cfg.zigbee}:/dev/zigbee"
      ]);

      # Environment variables
      environment = {
        TZ = config.time.timeZone;
        ISY_URL = "https://${cfg.isyHostName}";
        ZWAVE_URL = "https://${cfg.zwaveHostName}";
        HOST_IP = cfg.ip;
      };

      # Bind volume and db socket 
      volumes = [ 
        "${cfg.dataDir}:/config"
        "/run/postgresql:/run/postgresql"
      ];

    };

    # Copy configuration yaml and ensure includes exist
    file = let yaml = {
      type = "file"; mode = 775; 
      user = config.users.users.hass.uid; 
      group = config.users.groups.hass.gid;
    }; in  {
      "${cfg.dataDir}/automations.yaml" = yaml; 
      "${cfg.dataDir}/scripts.yaml" = yaml; 
      "${cfg.dataDir}/scenes.yaml" = yaml; 
      "${cfg.dataDir}/configuration.yaml" = yaml // { 
        source = ( writeText "configuration.yaml" (readFile ./configuration.yaml) );
      };
    };

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [ 
        8123  # home-assistant
        21063 # homekit
      ];
    };


  };

}
