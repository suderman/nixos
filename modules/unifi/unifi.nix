{ config, lib, pkgs, ... }:

let

  # https://hub.docker.com/r/jacobalberty/unifi/tags
  version = "7.5";

  cfg = config.modules.unifi;
  inherit (builtins) toString;
  inherit (lib) mkIf;
  inherit (config.modules) traefik;
  inherit (config.services.prometheus) exporters;

  httpsPort = 8443;
  httpPort = 8080;

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
      extraOptions = traefik.labels [ cfg.name httpsPort "https" ]

      # Networking
      ++ [ "--network=host" ];

      # Run as unifi user instead of root:
      # https://github.com/jacobalberty/unifi-docker/issues/509#issuecomment-1003727345
      environment = {
        UNIFI_HTTPS_PORT = toString httpsPort;
        UNIFI_HTTP_PORT = toString httpPort;
        UNIFI_UID = "${toString config.ids.uids.unifi}";
        UNIFI_GID = "${toString config.ids.gids.unifi}";
        RUNAS_UID0 = "false";
        BIND_PRIV = "false";
        TZ = config.time.timeZone;
      };

      # Bind volume
      volumes = [ "${cfg.dataDir}:/unifi" ];

    };

    # Create read-only user on Unifi controller named "unpoller" and then run this command:
    # sudo bash -c "echo p0llth3ml0gs > /var/lib/unifi/unpoller" 
    services.prometheus = {
      exporters.unpoller = {
        enable = true;
        controllers = [{
          user = "unpoller";
          pass = "${cfg.dataDir}/unpoller";
          url = "https://127.0.0.1:${toString httpsPort}";
          verify_ssl = false;
        }];
      };
      scrapeConfigs = [{ 
        job_name = "unpoller"; static_configs = [ 
          { targets = [ "127.0.0.1:${toString exporters.unpoller.port}" ]; } 
        ]; 
      }];
    };


    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [
        8880      # Port for HTTP portal redirect, if guest portal is enabled.
        8843      # Port for HTTPS portal redirect, ditto.
        6789      # Port for UniFi mobile speed test.
        httpPort  # Port for UAP to inform controller.
        httpsPort
      ];
      allowedUDPPorts = [
        3478  # UDP port used for STUN.
        10001 # UDP port used for device discovery.
      ];
    };

  };

}
