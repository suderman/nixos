{ config, lib, ... }:

let

  inherit (lib) mkIf mkBefore;
  inherit (builtins) toString;

  cfg = config.services.docker-hass;
  host = "zwave.${config.networking.fqdn}";
  stateDir = "${config.users.users.hass.home}/zwave";
  uid = toString config.users.users.hass.uid;
  gid = toString config.users.groups.hass.gid;

in {

  config = mkIf cfg.enable {

    networking.firewall = {
      allowedTCPPorts = [ 
        3000  # zwave websockets
        8091  # zwave web interface 
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
        "${stateDir}:/usr/src/app/store"
      ];
    };

    systemd.services.docker-zwave = {
      before = [ "docker-hass.service" ];
      requires = [ "docker-hass.service" ];
      preStart = mkBefore ''
        mkdir -p ${stateDir}
        chown -R ${uid}:${gid} ${stateDir}
      '';
    };

  };

}
