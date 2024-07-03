{ config, lib, this, ... }: let

  cfg = config.services.traefik;
  inherit (lib) mkIf mkOption mkDefault types;

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
    cleanRules = rule: replaceStrings [ " || Host(`PUBLIC`)" ] [ "" ] rule;

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
    fromAttrs = { url, ... }: mkDefault { headers.customRequestHeaders.Host = (mkHostName url); };
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
        publicFlag = if public' == true then " || Host(`PUBLIC`)" else "";
      in "Host(`${hostName}`)${publicFlag}";

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
        publicFlag = if public' == true then " || Host(`PUBLIC`)" else "";
      in "Host(`${hostName}`)${publicFlag}";

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

  options.services.traefik.lib = mkOption {
    type = types.anything; 
    readOnly = true; 
    default = { inherit mkHostName mkHostNames mkService mkMiddleware mkRouter mkLabels mkAlias; };
  };

}
