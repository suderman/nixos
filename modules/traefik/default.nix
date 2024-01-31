# modules.traefik.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.modules.traefik;
  certs = "${config.services.traefik.dataDir}/certs"; # dir for self-signed certificates

  inherit (lib) mkBefore mkForce mkIf mkOption options types;
  inherit (config.age) secrets;

in {

  options.modules.traefik = {
    enable = options.mkEnableOption "traefik"; 
    certificates = mkOption { 
      type = with types; listOf str;
      default = [ this.host "local" ];
    };
  };

  config = mkIf cfg.enable {

    # Give traefik user permission to read secrets
    users.users.traefik.extraGroups = [ "secrets" ]; 

    # Import the env file containing the CloudFlare token for cert renewal
    systemd.services.traefik.serviceConfig = {
      EnvironmentFile = [ secrets.traefik-env.path ];
    };

    # Self-signed certificate directory
    file."${certs}" = {
      type = "dir"; mode = 775; 
      user = "traefik";
      group = "traefik";
    };

    # Generate certificates with openssl
    systemd.services.traefik.preStart = let openssl = "${pkgs.openssl}/bin/openssl"; in mkBefore ''
      [[ -e ${certs}/key ]] || ${openssl} genrsa -out ${certs}/key 4096 
      echo "01" > ${certs}/serial 
      for NAME in ${builtins.toString cfg.certificates}; do
        export NAME
        ${openssl} req -new -key ${certs}/key -config ${./openssl.cnf} -extensions v3_req -subj "/CN=$NAME" -out ${certs}/csr 
        ${openssl} x509 -req -days 365 -in ${certs}/csr -extfile ${./openssl.cnf} -extensions v3_req -CA ${this.ca} -CAkey ${secrets.ca-key.path} -CAserial ${certs}/serial -out ${certs}/crt
        cat ${certs}/crt ${this.ca} > ${certs}/$NAME.crt
      done;
      rm -f ${certs}/csr ${certs}/crt
    '';

    # Create certificates for traefik dashboard
    modules.traefik.certificates = [ this.host "traefik.${this.host}" ];

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
          # http.redirections.entrypoint = {
          #   to = "websecure";
          #   scheme = "https";
          # };
        };

        # Run everything on 443
        entryPoints.websecure = {
          address = ":443";
        };

        # Let's Encrypt will check CloudFlare's DNS
        certificatesResolvers.resolver-dns.acme = {
          dnsChallenge.provider = "cloudflare";
          storage = "/var/lib/traefik/cert.json";
          email = "${this.host}@${domain}";
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

        http.routers = {
          traefik = {
            entrypoints = "websecure";
            rule = "Host(`${this.host}`) || Host(`traefik.${this.host}`)";
            tls = {};
            middlewares = "local@file";
            service = "api@internal";
          };
          
        };

        # Add every module certificate into the default store
        tls.certificates = map (name: { 
          certFile = "${certs}/${name}.crt"; 
          keyFile = "${certs}/key"; 
        }) cfg.certificates;

        # Also change the default certificate
        tls.stores.default.defaultCertificate = {
          certFile = "${certs}/${this.host}.crt"; 
          keyFile = "${certs}/key"; 
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
