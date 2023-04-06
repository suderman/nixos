{ config, lib, ... }:

let

  cfg = config.services.hass;
  uid = toString config.users.users.hass.uid;
  gid = toString config.users.groups.hass.gid;

  inherit (lib) mkIf mkBefore;
  inherit (builtins) toString;

in {

  config = mkIf (cfg.enable && cfg.zwave != "") {

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
        "--label=traefik.http.routers.zwave.rule=Host(`${cfg.zwaveHost}`)"
        "--label=traefik.http.routers.zwave.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.zwave.middlewares=local@file"
        "--label=traefik.http.services.zwave.loadbalancer.server.port=8091"
        "--label=traefik.http.services.zwave.loadbalancer.server.scheme=http"
        "--device=${cfg.zwave}:/dev/zwave"
        "--privileged"
        "--network=host"
        "--stop-signal=SIGINT"
        "-t"
      ];
      environment = {
        TZ = config.time.timeZone;
      };
      volumes = [ 
        "${cfg.dataDir}/zwave:/usr/src/app/store"
      ];
    };

    systemd.services.docker-zwave = {
      before = [ "docker-hass.service" ];
      wants = [ "docker-hass.service" ];
      preStart = mkBefore ''
        mkdir -p ${cfg.dataDir}/zwave
        chown -R ${uid}:${gid} ${cfg.dataDir}/zwave
      '';
    };

  };

}
