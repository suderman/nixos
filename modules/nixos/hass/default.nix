# services.docker-hass.enable = true;
{ config, lib, pkgs, ... }:

with config.networking;

let

  cfg = config.services.docker-hass;

  host = "hass.${hostName}.${domain}";
  stateDir = "/var/lib/hass";

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (builtins) toString;

in {

  options = {
    services.docker-hass.enable = lib.options.mkEnableOption "unifi-hass"; 
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
      allowedTCPPorts = [ 8123 21063 ];
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
        "--privileged"
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
    systemd.services.docker-hass.preStart = mkBefore ''
      mkdir -p ${stateDir}
      rm -rf ${stateDir}/configuration.yaml
      cp -f ${toString ./configuration.yaml} ${stateDir}/configuration.yaml
      chown -R ${toString config.ids.uids.hass}:${toString config.ids.gids.hass} ${stateDir}
    '';

  };

}
