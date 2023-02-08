{ config, lib, pkgs, ... }:

let
  cfg = config.services.traefik;
  inherit (lib) mkIf;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {

  # services.traefik.enable = true;
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
        dnsChallenge = {
          provider = "cloudflare";
          resolvers = "1.1.1.1:53,8.8.8.8:53";
          delaybeforecheck = "0";
        };
        storage = "/var/lib/traefik/cert.json";
        email = "dns@${domain}";
      };

      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

    };

    # Dynamic configuration
    dynamicConfigOptions = {

      # Basic Authentication is available. User/passwords are encrypted by agenix.
      http.middlewares = {
        basicauth.basicAuth.usersFile = mkIf age.enable age.secrets.basic-auth.path;
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
          rule = "Host(`local.${domain}`) || Host(`${hostName}.${domain}`)";
          service = "api@internal";
          tls.certresolver = "resolver-dns";
          tls.domains = [
            { main = "local.${domain}"; sans = "*.local.${domain}"; }
            { main = "${hostName}.${domain}"; sans = "*.${hostName}.${domain}"; }
          ];
        };
      };

    };
  };

  # Enable Docker and set to backend (over podman default)
  virtualisation = mkIf cfg.enable {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  # Open up the firewall for http and https
  networking.firewall.allowedTCPPorts = mkIf cfg.enable [ 80 443 ];

  # Import the env file containing the CloudFlare token for cert renewal
  systemd.services.traefik = mkIf cfg.enable {
    serviceConfig.EnvironmentFile = mkIf age.enable age.secrets.cloudflare-env.path;
  };

  # agenix
  age.secrets = mkIf age.enable {
    cloudflare-env = { file = age.files.cloudflare-env; };
    basic-auth = { file = age.files.basic-auth; owner = "traefik"; };
  };

}
