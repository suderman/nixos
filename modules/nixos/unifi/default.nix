# services.unifi-docker.enable = true;
{ config, lib, pkgs, ... }:

with config.networking;

let

  cfg = config.services.docker-unifi;
  stateDir = "/var/lib/unifi";
  host = "unifi.${hostName}.${domain}";
  id = 950;

  inherit (lib) mkIf mkOption types strings;

in {

  options = {
    services.docker-unifi.enable = lib.options.mkEnableOption "unifi-docker"; 
  };

  config = mkIf cfg.enable {

    users.users.unifi = {
      isSystemUser = true;
      group = "unifi";
      description = "UniFi controller daemon user";
      home = "${stateDir}";
      uid = id;
    };
    users.groups.unifi.gid = id;

    networking.firewall = {
      allowedTCPPorts = [
        8080  # Port for UAP to inform controller.
        8880  # Port for HTTP portal redirect, if guest portal is enabled.
        8843  # Port for HTTPS portal redirect, ditto.
        6789  # Port for UniFi mobile speed test.
      ];
      allowedUDPPorts = [
        3478  # UDP port used for STUN.
        10001 # UDP port used for device discovery.
      ];
    };

    # service
    virtualisation.oci-containers.containers."unifi" = {
      image = "jacobalberty/unifi:v7.3";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.unifi.rule=Host(`${host}`)"
        "--label=traefik.http.routers.unifi.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.unifi.middlewares=local@file"
        "--label=traefik.http.services.unifi.loadbalancer.server.port=8443"
        "--label=traefik.http.services.unifi.loadbalancer.server.scheme=https"
        "--network=host"
      ];
      volumes = [ "${stateDir}:/unifi" ];
      environment = {
        UNIFI_HTTP_PORT = "8080";
        UNIFI_HTTPS_PORT = "8443";
        UNIFI_UID = "${builtins.toString id}";
        UNIFI_GID = "${builtins.toString id}";
        RUNAS_UID0 = "false";
        BIND_PRIV = "false";
        TZ = config.time.timeZone;
      };
    };

  };

}
