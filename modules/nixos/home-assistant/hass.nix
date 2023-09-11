{ config, lib, pkgs, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString readFile;

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

    # Extend systemd service
    systemd.services.docker-home-assistant = {
      requires = [ "home-assistant.service" ];

      # Copy configuration to data directory before container starts up
      preStart = let 
        configuration_yaml = pkgs.writeText "configuration.yaml" (readFile ./configuration.yaml);
        uid = toString config.users.users.hass.uid;
        gid = toString config.users.groups.hass.gid;
      in mkBefore ''
        mkdir -p ${cfg.dataDir}
        rm -rf ${cfg.dataDir}/configuration.yaml
        cp -f ${configuration_yaml} ${cfg.dataDir}/configuration.yaml
        chown -R ${uid}:${gid} ${cfg.dataDir}
      '';

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
