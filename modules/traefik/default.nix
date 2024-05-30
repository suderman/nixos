# modules.traefik.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.modules.traefik;
  certs = "${config.services.traefik.dataDir}/certs"; # dir for self-signed certificates
  metricsPort = 81;
  acmeEmail = "dns@suderman.org";

  inherit (lib) attrNames mapAttrs mkForce mkIf mkOption options recursiveUpdate subtractLists types;
  inherit (this.lib) ls mkAttrs;
  inherit (config.age) secrets;

  # Generate a hostName from a url or name
  mkHostName = arg: let
    inherit (lib) hasInfix head removePrefix splitString;

    # Extract some.url hostName from https://some.url:443 
    fromUrl = url: let
      withoutProtocol = removePrefix "https://" ( removePrefix "http://" url );
      withoutPort = head( splitString ":" withoutProtocol );
      in withoutPort;

    # Generate hostName from name
    fromName = name: if ( hasInfix "." name ) 
      then name # if "name" has a . dot, use that
      else "${name}.${this.hostName}"; # else, prepend "name" to system's hostname

    in
      if hasInfix "://" arg
        then fromUrl arg 
        else fromName arg;

  # Retrieve all hostNames that Traefik knows about 
  mkHostNames = { public ? null, external ? null }: let
    inherit (builtins) attrValues concatMap filter replaceStrings split;
    inherit (lib) flatten hasInfix hasPrefix hasSuffix;

    # Extract different types of hostNames depending how they are "tagged" in the rule
    rules' = rule: hasInfix "Host(`" rule; 
    publicRules' = rule: ( hasInfix "Host(`" rule ) && ( hasInfix "`PUBLIC`" rule );
    privateRules' = rule: ( hasInfix "Host(`" rule ) && ( ! hasInfix "`PUBLIC`" rule );
    externalRules' = rule: ( hasInfix "Host(`" rule ) && ( ! hasInfix ".${this.hostName}`" rule );
    internalRules' = rule: ( hasInfix "Host(`" rule ) && ( hasInfix ".${this.hostName}`" rule );

    # First and second pass of filters
    certRules = if external == null then rules' else ( if external == true then externalRules' else internalRules' );
    domainRules = if public == null then rules' else ( if public == true then publicRules' else privateRules' );

    # Remove "PUBLIC" from all hostName rules
    cleanRules = rule: replaceStrings [ ",`PUBLIC`" ] [ "" ] rule;

    # Extract hostName from inside ( parenthesis )
    onlyHostNames = (elm: ( 
      ! hasInfix "(" elm && 
      ! hasInfix ")" elm && 
      ! hasInfix "," elm && 
      ! hasInfix " " elm 
    ) );

    routerHostNames = let
      # Collect router rules from traefik dynamic configuration options
      rules = flatten (map (router: [router.rule]) (attrValues config.services.traefik.dynamicConfigOptions.http.routers));
      # Filter further to only include router rules
      hostRules = map cleanRules (filter domainRules (filter certRules rules) );
      # Split each rule by backtick and collect list of hostNames
      hostNames = filter onlyHostNames (flatten (map (rule: (split "`" rule)) hostRules));
    in hostNames;

    labelHostNames = let
      # Collect extraOptions from all OCI containers 
      options = concatMap (container: container.extraOptions) (attrValues config.virtualisation.oci-containers.containers);
      # Filter to only include traefik labels
      rules = filter (option: hasPrefix "--label=traefik.http.routers" option) options;
      # Filter further to only include router rules
      hostRules = map cleanRules (filter domainRules (filter certRules rules) );
      # Split each rule by backtick and collect list of hostNames
      hostNames = filter onlyHostNames (flatten (map (rule: (split "`" rule)) hostRules));
    in hostNames;

    # Include "local" hostName when non-public and non-external 
    localHostName = if public != true && external != true then [ "local" ] else [];

  in localHostName ++ routerHostNames ++ labelHostNames;

  # Generate traefik service
  mkService = name: url: let
    inherit (builtins) isAttrs isString;
    fromString = url: fromAttrs { inherit url; };
    fromAttrs = { url, ... }: { 
      loadBalancer.servers = [{ inherit url; }];
    };
    in 
      if isString url then fromString url
      else if isAttrs url then fromAttrs url
      else {};

  # Generate traefik middleware
  mkMiddleware = name: url: let
    inherit (builtins) isAttrs isString;
    fromString = url: fromAttrs { inherit url; };
    fromAttrs = { url, ... }: { headers.customRequestHeaders.Host = mkHostName url; };
    in 
      if isString url then fromString url
      else if isAttrs url then fromAttrs url
      else {};

  # Generate traefik router
  mkRouter = name: url: let
    inherit (builtins) elem isAttrs isNull isString hasAttr;
    inherit (lib) hasSuffix;
    fromString = url: fromAttrs { inherit url; };
    fromAttrs = { hostName ? mkHostName name, tls ? null, public ? null, middlewares ? [], ... }: let

      # If the hostName is or ends with this system's hostName, assume internal DNS and private CA
      # If the hostName is anything else, assume external and needs public DNS with a certresolver
      external' = if elem hostName ([ this.hostName ] ++ cfg.extraInternalHostNames) || hasSuffix ".${this.hostName}" hostName then false else true;  
      # If public is boolean (explicitly set), just use that value. Otherwise, match with external.
      public' = if ! isNull public then public else external';

      # If public, then flag the rule
      rule' = let
        publicFlag = if public' == true then ",`PUBLIC`" else "";
      in "Host(`${hostName}`${publicFlag})";

      # If tls is boolean (explicitly set), just use that value
      tls' = if ! isNull tls then tls 
        # External hostNames will need a certresolver like Let's Encrypt to issue a certificate
        else if external' == true then { 
          certresolver = "resolver-dns";
          domains = [{
            main = "${hostName}"; 
            sans = "*.${hostName}"; 
          }];
        } else true; # Private hostNames will use certificates generated by the custom CA

      # Use websecure unless tls is explicitly false
      entrypoints' = if tls' == false then "web" else "websecure";

      # Include self-named middleware on both public and private
      # If NOT public (default), middlewares also include [ "local" ] to whitelist IPs
      middlewares' = if public' == true then [ name ] else [ name "local" ];

      in {
        entrypoints = entrypoints';
        rule = rule';
        tls = tls';
        middlewares = middlewares ++ middlewares';
        service = name;
      };   
    in 
      if isString url then fromString url
      else if isAttrs url then fromAttrs url
      else {};

  # Generate traefik labels for use with OCI container
  mkLabels = args: ( let
    inherit (builtins) elem elemAt head isAttrs isList isString length toBool toString;
    inherit (lib) hasSuffix replaceStrings;

    # If only passing a single argument, accept a string
    fromString = name: fromAttrs { inherit name; };

    # If passing name, port and scheme, accept a list
    fromList = args: fromAttrs { 
      name = (head args);
      port = if (length args > 1) then toString (elemAt args 1) else null;
      scheme = if (length args > 2) then toString (elemAt args 2) else null;
    };

    # For full customization, accept an attribute set
    fromAttrs = { name, hostName ? mkHostName name, tls ? null, public ? null, middlewares ? [], port ? null, scheme ?  null, ... }: let

      # Replace all dots with underscores
      name' = replaceStrings ["."] ["_"] name;

      # If the hostName is or ends with this system's hostName, assume internal DNS and private CA
      # If the hostName is anything else, assume external and needs public DNS with a certresolver
      external' = if elem hostName ([ this.hostName ] ++ cfg.extraInternalHostNames) || hasSuffix ".${this.hostName}" hostName then false else true;  
      # If public is boolean (explicitly set), just use that value. Otherwise, match with external.
      public' = if ! isNull public then public else external';

      # If public then flag the rule
      rule' = let
        publicFlag = if public' == true then ",`PUBLIC`" else "";
      in "Host(`${hostName}`${publicFlag})";

      # If tls is boolean (explicitly set), just use that value
      tls' = if ! isNull tls then tls 
        # External hostNames will need a certresolver like Let's Encrypt to issue a certificate
        else if external' == true then [
          "--label=traefik.http.routers.${name'}.tls.certresolver=resolver-dns"
          "--label=traefik.http.routers.${name'}.tls.domains[0].main=${hostName}"
          "--label=traefik.http.routers.${name'}.tls.domains[0].sans=*.${hostName}"
        ] else [ # Internal hostNames will use certificates generated by the custom CA
          "--label=traefik.http.routers.${name'}.tls=true"
        ];

      # If NOT public (default), middlewares include [ "local" ] to whitelist IPs
      middlewares' = if public' == true then middlewares else [
        "--label=traefik.http.routers.${name'}.middlewares=local@file" 
      ] ++ middlewares;

      # Port number
      port' = if (port == null) then [] else [
        "--label=traefik.http.services.${name'}.loadbalancer.server.port=${toString port}"
      ];

      # Scheme (http/https)
      scheme' = if (scheme == null) then [] else [
        "--label=traefik.http.services.${name'}.loadbalancer.server.scheme=${toString scheme}"
      ];

    # Add labels to Docker container so Traefik picks it up
    in [
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.${name'}.entrypoints=websecure"
      "--label=traefik.http.routers.${name'}.rule=${rule'}"
    ] ++ tls' ++ middlewares' ++ port' ++ scheme';

  in
    if isString args then fromString args
    else if isList args then fromList args
    else if isAttrs args then fromAttrs args
    else []
  );

  # Helper function to quickly add alias routers
  mkAlias = name: args: ( let
    inherit (builtins) head isAttrs isList isString tail;
    origin = mkHostName name;

    # If only passing a single argument, accept a string
    fromString = hostName: fromAttrs { inherit hostName; public = true; };

    # First element is hostName, second is public
    fromList = args: let
      hostName = head args;
      public = head (tail args);
    in fromAttrs { inherit hostName public; };

    # Require hostName, public defaults to true
    fromAttrs = { hostName, public ? true, ... }: let
      url = "https://${origin}";
    in { "${hostName}" =  { inherit url public; }; };

  in
    if isString args then fromString args
    else if isList args then fromList args
    else if isAttrs args then fromAttrs args
    else {}
  );

in {

  # Import all *.nix files in this directory
  imports = ls ./.;

  options.modules.traefik = {
    enable = options.mkEnableOption "traefik"; 

    # Shortcut for adding reverse proxies
    routers = mkOption { 
      type = with types; anything; 
      default = {};
    };

    # Helper function to automatically add traefik labels to OCI containers
    labels = mkOption {
      type = types.anything; 
      readOnly = true; 
      default = mkLabels;
    };

    # Helper function to quickly add alias routers
    alias = mkOption {
      type = types.anything; 
      readOnly = true; 
      default = mkAlias;
    };

    # Expose mkHostName function
    hostName = mkOption {
      type = types.anything; 
      readOnly = true; 
      default = mkHostName;
    };

    # Attributes merged with services.traefik.dynamicConfigOptions.http
    http = mkOption { 
      type = with types; anything; 
      default = {};
    };

    # All hostHames Traefik detects
    hostNames = mkOption { 
      type = with types; listOf str; default = [];
    };

    # OpenSSL certificates are created from this
    internalHostNames = mkOption { 
      type = with types; listOf str; default = [];
    };

    # Add additional hostNames to treat as internal
    extraInternalHostNames = mkOption { 
      type = with types; listOf str; default = [];
    };

    # LetsEncrypt certificates are created from this
    externalHostNames = mkOption { 
      type = with types; listOf str; 
      default = [];
    };

    # BlockyDNS mappings are created from this
    privateHostNames = mkOption { 
      type = with types; listOf str; default = [];
    };

    # CloudFlare DNS records are created from this
    publicHostNames = mkOption { 
      type = with types; listOf str; default = [];
    };

    # Collection of hostName to IP addresses from this Traefik configuration
    mapping = mkOption { 
      type = with types; anything; default = {}; 
    };

  };


  config = mkIf cfg.enable {

    # Combinations:
    # External / Public:  public service on Internet, using CloudFlare & Let's Encrypt
    # External / Private: personal service on LAN/VPN, using CloudFlare & Let's Encrypt
    # Internal / Private: personal service on LAN/VPN, using Blocky & OpenSSL (most common)
    # Internal / Public: invalid combination
    modules.traefik = {

      # All hostHames Traefik detects
      hostNames = mkHostNames {};

      # List of private hostNames using local DNS which will have certificates generated by custom CA
      # - OpenSSL certificates are created from this
      internalHostNames = mkHostNames { external = false; } ++ cfg.extraInternalHostNames;

      # List of external hostNames that need certificates generated externally by Let's Encrypt 
      # - LetsEncrypt certificates are created from this
      externalHostNames = subtractLists cfg.extraInternalHostNames ( mkHostNames { external = true; } );

      # List of private hostNames using local DNS which will have certificates generated by custom CA or Let's Encrypt
      # - BlockyDNS mappings are created from this
      privateHostNames = mkHostNames { public = false; };

      # List of public hostNames that require external DNS records in CloudFlare and certificates by Let's Encrypt
      # - CloudFlare DNS records are created from this
      publicHostNames = mkHostNames { public = true; };

      # Collection of hostName to IP addresses from this Traefik configuration
      mapping = mkAttrs cfg.privateHostNames ( _: this.domains.${this.hostName} );

    };

    # Give traefik user permission to read secrets
    users.users.traefik.extraGroups = [ "secrets" ]; 

    # CloudFlare DNS API Token 
    # > https://dash.cloudflare.com/profile/api-tokens
    # ---------------------------------------------------------------------------
    # CF_DNS_API_TOKEN=xxxxxx
    # ---------------------------------------------------------------------------
    systemd.services.traefik.serviceConfig = {
      EnvironmentFile = [ secrets.cloudflare-env.path ];
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
      for NAME in ${toString (unique cfg.internalHostNames)}; do
        export NAME IP=${this.domains.${this.hostName}}
        ${openssl} req -new -key ${certs}/key -config ${./openssl.cnf} -extensions v3_req -subj "/CN=$NAME" -out ${certs}/csr 
        ${openssl} x509 -req -days 365 -in ${certs}/csr -extfile ${./openssl.cnf} -extensions v3_req -CA ${this.ca} -CAkey ${secrets.ca-key.path} -CAserial ${certs}/serial -out ${certs}/crt
        cat ${certs}/crt ${this.ca} > ${certs}/$NAME.crt
      done;
      rm -f ${certs}/csr ${certs}/crt
    '';

    # Configure traefik service
    services.traefik = {
      enable = true;

      # v2.10.6
      package = pkgs.stable.traefik;

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
          # web.http.redirections.entrypoint = {
          #   to = "websecure";
          #   scheme = "https";
          # };

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
          email = acmeEmail;
        };

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

      };

      # Dynamic configuration
      dynamicConfigOptions = {

        http = recursiveUpdate { 

          # Generate traefik middlewares from configuration routers
          middlewares = ( 
            mapAttrs mkMiddleware cfg.routers 

          # Include a couple extra middlewares often used
          ) // {

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
          services = ( 
            mapAttrs mkService cfg.routers

          # Avoid a config error ensuring at least one service defined
          ) // { "noop" = {}; };

          # Generate traefik routers from configuration routers
          routers = (
            mapAttrs mkRouter cfg.routers
                
          # Make available the traefik dashboard
          ) // {
            traefik = {
              entrypoints = "websecure"; tls = {};
              rule = "Host(`${this.hostName}`, `traefik.${this.hostName}`)";
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
        }) cfg.internalHostNames;

        # Also change the default certificate
        tls.stores.default.defaultCertificate = {
          certFile = "${certs}/${this.hostName}.crt"; 
          keyFile = "${certs}/key"; 
        };

      };

    };

    # Configure prometheus to check traefik's metrics
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
    networking.firewall.allowedTCPPorts = [ 80 443 ];

  };

}
