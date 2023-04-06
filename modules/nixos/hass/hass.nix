# services.hass.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.services.hass;
  uid = toString config.users.users.hass.uid;
  gid = toString config.users.groups.hass.gid;

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

in {

  config = mkIf cfg.enable {

    networking.firewall = {
      allowedTCPPorts = [ 
        8123  # home-assistant
        21063 # homekit
      ];
    };

    virtualisation.oci-containers.containers."hass" = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.hass.rule=Host(`${cfg.host}`)"
        "--label=traefik.http.routers.hass.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.hass.middlewares=local@file"
        "--label=traefik.http.services.hass.loadbalancer.server.port=8123"
        "--label=traefik.http.services.hass.loadbalancer.server.scheme=http"
      ] ++ (if cfg.zigbee == "" then [] else [
        "--device=${cfg.zigbee}:/dev/zigbee"
      ]) ++ [
        "--privileged" 
        "--network=host"
      ];
      environment = {
        TZ = config.time.timeZone;
        ISY_URL = "https://${cfg.isyHost}";
        ZWAVE_URL = "https://${cfg.zwaveHost}";
        HOST_IP = cfg.ip;
      };
      volumes = [ 
        "${cfg.dataDir}:/config"
        "/run/postgresql:/run/postgresql"
      ];
    };

    # Postgres database configuration
    # This "hass" postgres user isn't actually being used to access the database.
    # Since the docker is running the container as root, the "root" postgres user
    # is what needs access, but that account already has access to all databases.
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "hass";
        ensurePermissions = { "DATABASE hass" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "hass" ];
    };

    # Ensure the database is brought up first
    systemd.services.docker-hass.requires = [ "postgresql.service" ];
    systemd.services.docker-hass.after = [ "postgresql.service" ];

    # Try to bring up zwave too
    systemd.services.docker-hass.wants = [ "docker-zwave.service" ];

    # Copy configuration to state directory before container starts up
    systemd.services.docker-hass.preStart = let
      configuration_yaml = pkgs.writeText "configuration.yaml" (readFile ./configuration.yaml);
    in mkBefore ''
      mkdir -p ${cfg.dataDir}
      rm -rf ${cfg.dataDir}/configuration.yaml
      cp -f ${configuration_yaml} ${cfg.dataDir}/configuration.yaml
      chown -R ${uid}:${gid} ${cfg.dataDir}
    '';

  };

}
