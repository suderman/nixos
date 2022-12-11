{ inputs, config, pkgs, lib, ... }: 

let 
  email = "dns@${config.networking.domain}";
  domain = "${config.networking.domain}";
  localDomain = "local.${config.networking.domain}";
  hostDomain = "${config.networking.hostName}.${config.networking.domain}";

in {

  # Open up the firewall for http and https
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Import the env file containing the CloudFlare token for cert renewal
  systemd.services.traefik = {
    serviceConfig.EnvironmentFile = config.age.secrets.cloudflare-env.path;
  };

  # Configure the Nix traefik service
  services.traefik = {
    enable = true;
    group = "docker"; # required so traefik is permitted to watch docker events

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
        email = "${email}";
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
        basicauth.basicAuth.usersFile = config.age.secrets.basic-auth.path;
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
          rule = "Host(`traefik.${localDomain}`) || Host(`traefik.${hostDomain}`)";
          service = "api@internal";
          tls.certresolver = "resolver-dns";
          tls.domains = [
            { main = "${localDomain}"; sans = "*.${localDomain}"; }
            { main = "${hostDomain}"; sans = "*.${hostDomain}"; }
          ];
        };
      };

    };
  };


  # networking.extraHosts = ''
  #   127.0.0.1 traefik.cog
  # '';

}
