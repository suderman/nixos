# modules.traefik.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.modules.traefik;
  certs = "${config.services.traefik.dataDir}/certs"; # dir for self-signed certificates
  metricsPort = 81;

  inherit (lib) attrNames mapAttrs mkForce mkIf mkOption options recursiveUpdate types;
  inherit (this.lib) ls;
  inherit (config.age) secrets;

  # Generate traefik labels for use with OCI container
  labels = x: ( let
    inherit (builtins) elemAt isList isString length toString;
    fromString = name: fromList [ name ];
    fromList = args: let 
      name = (elemAt args 0);
      port = if (length args > 1) then toString (elemAt args 1) else "";
      scheme = if (length args > 2) then toString (elemAt args 2) else "";
    in [
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.${name}.rule=Host(`${name}.${this.hostName}`)"
      "--label=traefik.http.routers.${name}.tls=true"
      "--label=traefik.http.routers.${name}.middlewares=local@file" 
    ] ++ ( if port == "" then [] else [
      "--label=traefik.http.services.${name}.loadbalancer.server.port=${port}"
    ]) ++ ( if scheme == "" then [] else [
      "--label=traefik.http.services.${name}.loadbalancer.server.scheme=${scheme}"
    ]);
  in
    if (isString x) then (fromString x)
    else if (isList x) then (fromList x)
    else []
  );

in {

  imports = ls ./.;

  options.modules.traefik = {
    enable = options.mkEnableOption "traefik"; 
    http = mkOption { 
      type = with types; anything; default = {};
    };
    routers = mkOption { 
      type = with types; anything; default = {};
    };
    labels = mkOption {
      type = types.anything; readOnly = true; default = labels;
    };
    certificates = mkOption { 
      type = with types; listOf str;
      default = [ this.hostName "local" ];
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
    systemd.services.traefik.preStart = let 
      inherit (builtins) toString;
      inherit (lib) mkBefore unique;
      openssl = "${pkgs.openssl}/bin/openssl"; 
    in mkBefore ''
      [[ -e ${certs}/key ]] || ${openssl} genrsa -out ${certs}/key 4096 
      [[ -e ${certs}/serial ]] || echo "01" > ${certs}/serial 
      for NAME in ${toString (unique cfg.certificates)}; do
        export NAME IP=${this.domains.${this.hostName}}
        ${openssl} req -new -key ${certs}/key -config ${./openssl.cnf} -extensions v3_req -subj "/CN=$NAME" -out ${certs}/csr 
        ${openssl} x509 -req -days 365 -in ${certs}/csr -extfile ${./openssl.cnf} -extensions v3_req -CA ${this.ca} -CAkey ${secrets.ca-key.path} -CAserial ${certs}/serial -out ${certs}/crt
        cat ${certs}/crt ${this.ca} > ${certs}/$NAME.crt
      done;
      rm -f ${certs}/csr ${certs}/crt
    '';

    # Create list of host names including host, reverse proxies and OCI container labels
    modules.traefik.certificates = let
      inherit (builtins) attrValues concatMap filter split;
      inherit (lib) flatten hasInfix hasPrefix hasSuffix;

      routerHostNames = let
        # Collect router rules from traefik dynamic configuration options
        rules = flatten (map (router: [router.rule]) (attrValues config.services.traefik.dynamicConfigOptions.http.routers));
        # Filter rules to the server's host name, starting with a period & ending with backtick parenthesis: .HOSTNAME`)
        hostRules = filter (rule: hasInfix ".${this.hostName}`)" rule) rules;
        # Split each rule by backtick and collect list elements that end with server's hostname (starting with a period) 
        hostNames = filter (elm: hasSuffix ".${this.hostName}" elm) (flatten (map (rule: (split "`" rule)) hostRules));
      in hostNames;

      labelHostNames = let
        # Collect extraOptions from all OCI containers 
        options = concatMap (container: container.extraOptions) (attrValues config.virtualisation.oci-containers.containers);
        # Filter to only include traefik labels
        labels = filter (option: hasPrefix "--label=traefik.http.routers" option) options;
        # Filter further to only include router rules
        rules = filter (label: hasInfix ".rule=Host(`" label) labels;
        # Filter rules to the server's host name, starting with a period & ending with backtick parenthesis: .HOSTNAME`)
        hostRules = filter (label: hasInfix ".${this.hostName}`)" label) labels;
        # Split each rule by backtick and collect list elements that end with server's hostname (starting with a period) 
        hostNames = filter (elm: hasSuffix ".${this.hostName}" elm) (flatten (map (rule: (split "`" rule)) hostRules));
      in hostNames;

    in [ this.hostName ] ++ routerHostNames ++ labelHostNames;


    # Configure traefik service
    services.traefik = {
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
        entryPoints = {

          # Run everything on 443
          websecure.address = ":443";

          # Redirect http to https
          web.address = ":80";
          web.http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
          };

          # Metrics for prometheus
          metrics.address = ":${toString metricsPort}";

        };

        metrics.prometheus = {
          entryPoint = "metrics";
          buckets = [ "0.100000" "0.300000" "1.200000" "5.000000" ];
          addServicesLabels = true;
          addEntryPointsLabels = true;
        };

        # Let's Encrypt will check CloudFlare's DNS
        certificatesResolvers.resolver-dns.acme = {
          dnsChallenge.provider = "cloudflare";
          storage = "/var/lib/traefik/cert.json";
          email = "${this.hostName}@${config.networking.domain}";
        };

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

      };

      # Dynamic configuration
      dynamicConfigOptions = {

        http = recursiveUpdate { 
          middlewares = {

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

          # Generate traefik services from configuration routers
          services = { "noop" = {}; } // 
            ( mapAttrs ( name: url: {
              loadBalancer.servers = [{ inherit url; }];
            }) cfg.routers );

          # Generate traefik routers from configuration routers
          routers = (
            mapAttrs ( name: url: {
              rule = "Host(`${name}.${this.hostName}`)";
              entrypoints = "websecure"; tls = true;
              middlewares = "local";
              service = name;
            }) cfg.routers 

          # Make available the traefik dashboard
          ) // {
            traefik = {
              entrypoints = "websecure"; tls = {};
              rule = "Host(`${this.hostName}`) || Host(`traefik.${this.hostName}`)";
              middlewares = "local";
              service = "api@internal";
            }; 
          };

        # Merge with http option from traefik module 
        } cfg.http; 

        # Add every module certificate into the default store
        tls.certificates = map (name: { 
          certFile = "${certs}/${name}.crt"; 
          keyFile = "${certs}/key"; 
        }) cfg.certificates;

        # Also change the default certificate
        tls.stores.default.defaultCertificate = {
          certFile = "${certs}/${this.hostName}.crt"; 
          keyFile = "${certs}/key"; 
        };

      };

    };

    services.prometheus = {
      scrapeConfigs = [{ 
        job_name = "traefik"; static_configs = [ 
          { targets = [ "127.0.0.1:${toString metricsPort}" ]; } 
        ]; 
      }];
    };

    # Enable Docker and set to backend (over podman default)
    virtualisation = {
      docker.enable = true;
      docker.storageDriver = "overlay2";
      oci-containers.backend = "docker";
    };

    # Open up the firewall for http and https
    networking.firewall.allowedTCPPorts = [ 80 443 metricsPort ];

  };

}
