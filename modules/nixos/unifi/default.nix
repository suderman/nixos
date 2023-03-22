# services.docker-unifi.enable = true;
{ config, lib, pkgs, ... }:

with config.networking;

let

  cfg = config.services.docker-unifi;

  host = "unifi.${hostName}.${domain}";
  stateDir = "/var/lib/unifi";

  gateway = {
    host = "logos.${hostName}.${domain}";
    ip = "192.168.1.1";
  };

  inherit (lib) mkIf mkOption types strings;
  inherit (builtins) toString;

in {

  options = {
    services.docker-unifi.enable = lib.options.mkEnableOption "docker-unifi"; 
  };

  config = mkIf cfg.enable {

    # Used to be set in nixpkgs, restoring here
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.unifi = 183;
    ids.gids.unifi = 183;

    # Inspired from services.unifi
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/unifi.nix
    users.users.unifi = {
      isSystemUser = true;
      group = "unifi";
      description = "UniFi controller daemon user";
      home = "${stateDir}";
      uid = config.ids.uids.unifi;
    };
    users.groups.unifi.gid = config.ids.gids.unifi;

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

    # This docker image is more reliable than the nixpkgs version, at least for now.
    # The controller requires a dated version of mongodb that nixpkgs has dropped.
    # https://github.com/NixOS/nixpkgs/commit/45d27d43c4dfc0eb6f6b55aa9fbdfb90513271df
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
      # Run as unifi user instead of root:
      # https://github.com/jacobalberty/unifi-docker/issues/509#issuecomment-1003727345
      environment = {
        UNIFI_HTTPS_PORT = "8443";
        UNIFI_HTTP_PORT = "8080";
        UNIFI_UID = "${toString config.ids.uids.unifi}";
        UNIFI_GID = "${toString config.ids.gids.unifi}";
        RUNAS_UID0 = "false";
        BIND_PRIV = "false";
        TZ = config.time.timeZone;
      };
      volumes = [ "${stateDir}:/unifi" ];
    };

    # also traefik proxy for gateway "logos"
    services.traefik.dynamicConfigOptions.http = {
      routers.logos = {
        rule = "Host(`${gateway.host}`)";
        middlewares = "local@file";
        tls.certresolver = "resolver-dns";
        service = "logos";
      };
      services.logos.loadBalancer.servers = [{ url = "https://${gateway.ip}:443"; }];
    };

  };

}
