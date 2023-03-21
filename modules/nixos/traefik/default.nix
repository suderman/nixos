# services.traefik.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.services.traefik;
  inherit (lib) mkIf;

  # # agenix secrets combined with age files paths
  # age = config.age // { 
  #   files = config.secrets.files; 
  #   enable = config.secrets.enable; 
  # };
  secrets = config.age.secrets;

in {

  config = mkIf cfg.enable {

    # # agenix
    # age.secrets = mkIf age.enable {
    #   cloudflare-env = { file = age.files.cloudflare-env; };
    #   basic-auth = { file = age.files.basic-auth; owner = "traefik"; };
    # };

    # agenix
    secrets.basic-auth.owner = "traefik";

    # Import the env file containing the CloudFlare token for cert renewal
    systemd.services.traefik = {
      # serviceConfig.EnvironmentFile = mkIf age.enable age.secrets.cloudflare-env.path;
      serviceConfig.EnvironmentFile = secrets.cloudflare-env.path;
    };

    services.traefik = with config.networking; {

      # Required so traefik is permitted to watch docker events
      group = "docker"; 

      # Static configuration
      staticConfigOptions = {

        api.insecure = true;
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
          # login.basicAuth.usersFile = mkIf age.enable age.secrets.basic-auth.path;
          login.basicAuth.usersFile = secrets.basic-auth.path;

          # Whitelist local network and VPN addresses
          local.ipWhiteList.sourceRange = [ 
            "127.0.0.1/32"   # local host
            "192.168.0.0/16" # local network
            "10.0.0.0/8"     # local network
            "172.16.0.0/12"  # local network
            "100.64.0.0/10"  # vpn network
          ];

        };

        # Traefik dashboard
        http.services = {
          traefik = {
            loadbalancer.servers = [{ url = "http://127.0.0.1:8080"; }];
          };
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
      oci-containers.backend = "docker";
    };

    # Open up the firewall for http and https
    networking.firewall.allowedTCPPorts = [ 80 443 ];

  };

}
