# services.docker-hass.enable = true;
{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

  cfg = config.services.docker-hass;
  host = "hass.${config.networking.hostName}.${config.networking.domain}";
  stateDir = "/var/lib/hass";

in {

  options = {
    services.docker-hass.enable = mkEnableOption "docker-hass"; 
  };

  config = mkIf cfg.enable {

    # Inspired from services.home-assistant
    users.users.hass = {
      isSystemUser = true;
      group = "hass";
      description = "Home Assistant daemon user";
      home = "${stateDir}";
      uid = config.ids.uids.hass;
    };
    users.groups.hass.gid = config.ids.gids.hass;

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
        "--label=traefik.http.routers.hass.rule=Host(`${host}`)"
        "--label=traefik.http.routers.hass.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.hass.middlewares=local@file"
        "--label=traefik.http.services.hass.loadbalancer.server.port=8123"
        "--label=traefik.http.services.hass.loadbalancer.server.scheme=http"
        "--network=host"
        "--privileged" # access to host devices (zigbee, zwave, etc)
      ];
      # user = "hass:hass";
      environment = {
        TZ = config.time.timeZone;
      };
      volumes = [ 
        "${stateDir}:/config"
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
    systemd.services.docker-hass.after = [ "postgresql.service" ];
    systemd.services.docker-hass.requires = [ "postgresql.service" ];

    # Copy configuration to state directory before container starts up
    systemd.services.docker-hass.preStart = let
      configuration_yaml = pkgs.writeText "configuration.yaml" (readFile ./configuration.yaml);
    in mkBefore ''
      mkdir -p ${stateDir}
      rm -rf ${stateDir}/configuration.yaml
      cp -f ${configuration_yaml} ${stateDir}/configuration.yaml
      chown -R ${toString config.ids.uids.hass}:${toString config.ids.gids.hass} ${stateDir}
    '';

  };

}
