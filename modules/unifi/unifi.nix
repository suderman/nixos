{ config, lib, pkgs, ... }:

let

  # https://hub.docker.com/r/jacobalberty/unifi/tags
  version = "7.5";

  cfg = config.modules.unifi;
  inherit (builtins) toString;
  inherit (lib) mkIf;
  inherit (config.modules) traefik;

in {

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # This docker image is more reliable than the nixpkgs version, at least for now.
    # The controller requires a dated version of mongodb that nixpkgs has dropped.
    # https://github.com/NixOS/nixpkgs/commit/45d27d43c4dfc0eb6f6b55aa9fbdfb90513271df
    virtualisation.oci-containers.containers."unifi" = {
      image = "jacobalberty/unifi:v${version}";
      autoStart = false;

      # Traefik labels
      extraOptions = traefik.labels [ cfg.name 8443 "https" ]

      # Networking
      ++ [ "--network=host" ];

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

      # Bind volume
      volumes = [ "${cfg.dataDir}:/unifi" ];

    };

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [
        8080  # Port for UAP to inform controller.
        8880  # Port for HTTP portal redirect, if guest portal is enabled.
        8843  # Port for HTTPS portal redirect, ditto.
        6789  # Port for UniFi mobile speed test.
        8443
      ];
      allowedUDPPorts = [
        3478  # UDP port used for STUN.
        10001 # UDP port used for device discovery.
      ];
    };

  };

}
