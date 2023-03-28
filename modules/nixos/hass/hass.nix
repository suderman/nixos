# services.docker-hass.enable = true;
{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

  cfg = config.services.docker-hass;
  host = "hass.${config.networking.fqdn}";
  stateDir = config.users.users.hass.home;
  uid = toString config.users.users.hass.uid;
  gid = toString config.users.groups.hass.gid;

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
        "--label=traefik.http.routers.hass.rule=Host(`${host}`)"
        "--label=traefik.http.routers.hass.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.hass.middlewares=local@file"
        "--label=traefik.http.services.hass.loadbalancer.server.port=8123"
        "--label=traefik.http.services.hass.loadbalancer.server.scheme=http"
        # "--device=${config.services.docker-hass.zigbee}:/dev/zigbee"
        # "--device=${config.services.docker-hass.insteon}:/dev/insteon"
        "--privileged" 
        "--network=host"
      ];
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
      chown -R ${uid}:${gid} ${stateDir}
    '';

  };

}
