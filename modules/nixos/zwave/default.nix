# services.docker-zwave.enable = true;
{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkBefore;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString;

  cfg = config.services.docker-zwave;
  host = "zwave.${config.networking.hostName}.${config.networking.domain}";
  stateDir = "/var/lib/hass/zwave";

in {

  options = {
    services.docker-zwave.enable = mkEnableOption "docker-zwave"; 
  };

  config = mkIf cfg.enable {

    networking.firewall = {
      allowedTCPPorts = [ 
        3000 # websocket
        8091 # web interface 
      ];
    };

    virtualisation.oci-containers.containers."zwave" = {
      image = "zwavejs/zwave-js-ui:latest";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.zwave.rule=Host(`${host}`)"
        "--label=traefik.http.routers.zwave.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.zwave.middlewares=local@file"
        "--label=traefik.http.services.zwave.loadbalancer.server.port=8091"
        "--label=traefik.http.services.zwave.loadbalancer.server.scheme=http"
        "--privileged" # access to host devices (zigbee, zwave, etc)
        "--stop-signal=SIGINT"
        "--network=host"
        "-t"
      ];
      environment = {
        TZ = config.time.timeZone;
      };
      volumes = [ 
        "${stateDir}:/usr/src/app/store"
      ];
    };

    systemd.services.docker-zwave = {
      requires = [ "docker-hass.service" ];
      before = [ "docker-hass.service" ];
      preStart = mkBefore ''
        mkdir -p ${stateDir}
        chown -R ${toString config.ids.uids.hass}:${toString config.ids.gids.hass} ${stateDir}
      '';
    };

  };

}
