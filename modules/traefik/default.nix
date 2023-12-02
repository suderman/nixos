# modules.traefik.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.traefik;
  secrets = config.age.secrets;
  inherit (lib) mkIf options;

in {

  options.modules.traefik.enable = options.mkEnableOption "traefik"; 

  config = mkIf cfg.enable {

    # agenix
    users.users.traefik.extraGroups = [ "secrets" ]; 

    # Import the env file containing the CloudFlare token for cert renewal
    systemd.services.traefik = {
      serviceConfig.EnvironmentFile = [ secrets.traefik-env.path ];
    };

    services.traefik = with config.networking; {

      enable = true;

      # Required so traefik is permitted to watch docker events
      group = "docker"; 

      # Static configuration
      staticConfigOptions = {

        api.insecure = false;
        api.dashboard = true;
        pilot.dashboard = false;

        # Allow backend services to have self-signed certs
        serversTransport.insecureSkipVerify = true;

        # Watch docker events and discover services
        providers.docker = {
          endpoint = "unix:///var/run/docker.sock";
          exposedByDefault = false;
        };

        # Listen on port 80 and redirect to port 443
        entryPoints.web = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
          };
        };

        # Run everything on 443
        entryPoints.websecure = {
          address = ":443";
        };

        # Let's Encrypt will check CloudFlare's DNS
        certificatesResolvers.resolver-dns.acme = {
          dnsChallenge.provider = "cloudflare";
          storage = "/var/lib/traefik/cert.json";
          email = "${hostName}@${domain}";
        };

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

      };

      # Dynamic configuration
      dynamicConfigOptions = {

        http.middlewares = {

          # Basic Authentication is available. User/passwords are encrypted by agenix.
          login.basicAuth.usersFile = secrets.basic-auth.path;

          # Whitelist local network and VPN addresses
          local.ipWhiteList.sourceRange = [ 
            "127.0.0.1/32"   # local host
            "192.168.0.0/16" # local network
            "10.0.0.0/8"     # local network
            "172.16.0.0/12"  # docker network
            "100.64.0.0/10"  # vpn network
          ];

        };

        # Set up wildcard domain certificates for both *.hostname.domain and *.local.domain
        http.routers = {
          traefik = {
            entrypoints = "websecure";
            rule = "Host(`${hostName}.${domain}`) || Host(`local.${domain}`)";
            tls.certresolver = "resolver-dns";
            tls.domains = [{
              main = "${hostName}.${domain}"; 
              sans = "*.${hostName}.${domain},local.${domain},*.local.${domain}"; 
            }];
            middlewares = "local@file";
            service = "api@internal";
          };
          
        };

      };
    };

    # Enable Docker and set to backend (over podman default)
    virtualisation = {
      docker.enable = true;
      docker.storageDriver = "overlay2";
      oci-containers.backend = "docker";
    };

    # Open up the firewall for http and https
    networking.firewall.allowedTCPPorts = [ 80 443 ];

  };

}
