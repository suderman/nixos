# services.docker-hass.enable = true;
{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

  cfg = config.services.docker-hass;

  hass = {
    host = "hass.${config.networking.hostName}.${config.networking.domain}";
    stateDir = "/var/lib/hass";
  };
  
  zwave = {
    host = "zwave.${config.networking.hostName}.${config.networking.domain}";
    stateDir = "${hass.stateDir}/zwave";
  };

in {

  options = {
    services.docker-hass.enable = mkEnableOption "docker-hass"; 
    services.docker-hass.zigbee = mkOption {
      description = "Path to Zigbee USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0" ];
    };
    services.docker-hass.insteon = mkOption {
      description = "Path to Insteon USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_DVADb116L16-if00-port0" ];
    };
    services.docker-hass.zwave = mkOption {
      description = "Path to Zwave USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-0658_0200-if00" ];
    };
  };

  config = mkIf cfg.enable {

    # Inspired from services.home-assistant
    users.users.hass = {
      isSystemUser = true;
      group = "hass";
      description = "Home Assistant daemon user";
      home = "${hass.stateDir}";
      uid = config.ids.uids.hass;
    };
    users.groups.hass.gid = config.ids.gids.hass;

    networking.firewall = {
      allowedTCPPorts = [ 
        8123  # home-assistant
        21063 # homekit
        3000  # zwave websockets
        8091  # zwave web interface 
      ];
    };

    virtualisation.oci-containers.containers."hass" = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.hass.rule=Host(`${hass.host}`)"
        "--label=traefik.http.routers.hass.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.hass.middlewares=local@file"
        "--label=traefik.http.services.hass.loadbalancer.server.port=8123"
        "--label=traefik.http.services.hass.loadbalancer.server.scheme=http"
        "--device=${config.services.docker-hass.zigbee}:/dev/zigbee"
        "--device=${config.services.docker-hass.insteon}:/dev/insteon"
        "--privileged" 
        "--network=host"
      ];
      environment = {
        TZ = config.time.timeZone;
      };
      volumes = [ 
        "${hass.stateDir}:/config"
        "/run/postgresql:/run/postgresql"
      ];
    };

    virtualisation.oci-containers.containers."zwave" = {
      image = "zwavejs/zwave-js-ui:latest";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.zwave.rule=Host(`${zwave.host}`)"
        "--label=traefik.http.routers.zwave.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.zwave.middlewares=local@file"
        "--label=traefik.http.services.zwave.loadbalancer.server.port=8091"
        "--label=traefik.http.services.zwave.loadbalancer.server.scheme=http"
        "--device=${config.services.docker-hass.zwave}:/dev/zwave"
        "--privileged"
        "--network=host"
        "--stop-signal=SIGINT"
        "-t"
      ];
      environment = {
        TZ = config.time.timeZone;
      };
      volumes = [ 
        "${zwave.stateDir}:/usr/src/app/store"
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
    systemd.services.docker-zwave.before = [ "docker-hass.service" ];
    systemd.services.docker-zwave.requires = [ "docker-hass.service" ];

    # Copy configuration to state directory before container starts up
    systemd.services.docker-hass.preStart = let
      configuration_yaml = pkgs.writeText "configuration.yaml" (readFile ./configuration.yaml);
    in mkBefore ''
      mkdir -p ${zwave.stateDir}
      rm -rf ${hass.stateDir}/configuration.yaml
      cp -f ${configuration_yaml} ${hass.stateDir}/configuration.yaml
      chown -R ${toString config.ids.uids.hass}:${toString config.ids.gids.hass} ${hass.stateDir}
    '';

  };

}
