{ config, lib, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf mkBefore;
  inherit (builtins) toString;

in {

  config = mkIf (cfg.enable && cfg.zwave != "") {

    # Z-Wave JS UI container
    virtualisation.oci-containers.containers.zwave = {
      image = "ghcr.io/zwave-js/zwave-js-ui:${cfg.zwaveVersion}";
      autoStart = false;

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.zwave.rule=Host(`${cfg.zwaveHostName}`)"
        "--label=traefik.http.routers.zwave.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.zwave.middlewares=local@file"
        "--label=traefik.http.services.zwave.loadbalancer.server.port=8091"
        "--label=traefik.http.services.zwave.loadbalancer.server.scheme=http"

      # Networking and devices
      ] ++ [
        "--privileged"
        "--network=host"
      ] ++ [
        "--device=${cfg.zwave}:/dev/zwave"
        "--stop-signal=SIGINT"
        "-t"
      ];

      # Environment variables
      environment = {
        TZ = config.time.timeZone;
      };

      # Bind volume
      volumes = [ 
        "${cfg.dataDir}/zwave:/usr/src/app/store"
      ];

    };

    # Extend systemd service
    systemd.services.docker-zwave = {
      requires = [ "home-assistant.service" ];

      # Ensure directory and permissions
      preStart = let 
        uid = toString config.users.users.hass.uid;
        gid = toString config.users.groups.hass.gid;
      in mkBefore ''
        mkdir -p ${cfg.dataDir}/zwave
        chown -R ${uid}:${gid} ${cfg.dataDir}/zwave
      '';

    };

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [ 
        3000  # zwave websockets
        8091  # zwave web interface 
      ];
    };

  };

}
