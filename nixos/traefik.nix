{ inputs, config, pkgs, lib, ... }: 

let 
  email = "dns@${config.networking.domain}";
  domain = "${config.networking.domain}";
  localDomain = "local.${config.networking.domain}";
  hostDomain = "${config.networking.hostName}.${config.networking.domain}";
in {

  # age.secrets.cf_dns_api_token.file = "${inputs.self}/secrets/cf_dns_api_token.age";
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  systemd.services.traefik = {
    serviceConfig.EnvironmentFile = config.age.secrets.cf_dns_api_token.path;
  };

  services.traefik = {
    enable = true;
    group = "docker"; # required so traefik is permitted to watch docker events

    staticConfigOptions = {

      api.insecure = true;
      api.dashboard = true;
      pilot.dashboard = false;
      serversTransport.insecureSkipVerify = true;

      providers.docker = {
        endpoint = "unix:///var/run/docker.sock";
        exposedByDefault = false;
      };

      entryPoints.web = {
        address = ":80";
        http.redirections.entrypoint = {
          to = "websecure";
          scheme = "https";
        };
      };

      entryPoints.websecure = {
        address = ":443";
      };

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

    dynamicConfigOptions = {

      http.services = {
        traefik = {
          loadbalancer.servers = [{ url = "http://127.0.0.1:8080"; }];
        };
      };

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

        # http.routers.router2.rule = "Host(`ocis.cog`)";
        # http.routers.router2.service = "service2";
        # http.services.service2.loadBalancer.servers = [{ url = "http://localhost:9200"; }];
      };

    };
  };


  # networking.extraHosts = ''
  #   127.0.0.1 traefik.cog search.cog ocis.cog
  # '';

}
