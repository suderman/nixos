# services.blocky.enable = true;
{ config, lib, pkgs, this, outputs, ... }: let 

  cfg = config.services.blocky;
  inherit (builtins) attrValues mapAttrs toString;
  inherit (lib) concatStringsSep flatten foldl mkIf mkOption mkForce types;

in {

  options.services.blocky = {
    name = mkOption {
      type = types.str;
      default = "blocky";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/blocky"; 
    };
    dnsPort = mkOption {
      type = types.port;
      default = 53; 
    };
    httpPort = mkOption {
      type = types.port;
      default = 4000; 
    };

    # Default is to not provide DNS services to the public Internet
    public = mkOption {
      type = types.bool;
      default = false; 
    };

    # Collection of hostName to IP addresses from all Traefik configurations
    mapping = mkOption { 
      type = with types; anything; 
      readOnly = true;
      default = foldl (a: b: a // b) {} ( 
        attrValues ( mapAttrs ( name: host: host.config.services.traefik.mapping ) outputs.nixosConfigurations )
      );
    };

  };

  # Use blocky to add custom domains and block unwanted domains
  config = mkIf cfg.enable {

    # Enable reverse proxy for api
    # https://blocky.hub/api/blocking/status
    services.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.httpPort}";
    };

    # Ensure directory exists for downloaded lists
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 775; 
    };

    # Blocky supports downloading lists automatically, but sometimes timeouts on slow connections. 
    # Get around that by downloading these lists separately as a systemd service
    systemd.services.blocky-download-lists = {
      description = "Download copy of lists for Blocky";
      after = [ "multi-user.target" ];
      requires = [ "multi-user.target" ];
      wantedBy = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      path = with pkgs; [ curl ];
      script = ''
        curl https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/light.txt > ${cfg.dataDir}/blacklist.txt
        curl https://nsfw.oisd.nl/domainswild > ${cfg.dataDir}/nsfw.txt
        curl https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt > ${cfg.dataDir}/whitelist.txt
        curl https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt > ${cfg.dataDir}/whitelist-optional.txt
      '';
    };

    # Run this script every day
    systemd.timers.blocky-download-lists = {
      wantedBy = [ "timers.target" ];
      partOf = [ "blocky-download-lists.service" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "blocky-download-lists.service";
      };
    };

    services.prometheus = {
      scrapeConfigs = [{ 
        job_name = "blocky"; static_configs = [ 
          { targets = [ "127.0.0.1:${toString cfg.httpPort}" ]; } 
        ]; 
      }];
    };

    # Public firewall rules
    networking.firewall = if cfg.public == true then {
      allowedTCPPorts = [ cfg.dnsPort cfg.httpPort ];
      allowedUDPPorts = [ cfg.dnsPort ];

    # Private firewall rules (default)
    } else {

      extraCommands = let
        dnsPort = toString cfg.dnsPort;
        httpPort = toString cfg.httpPort;

        # We only want blocky to be available to local and VPN requests
        localRanges = [
          "127.0.0.1/32"   # local host
          "192.168.0.0/16" # local network
          "10.0.0.0/8"     # local network
          "172.16.0.0/12"  # docker network
          "100.64.0.0/10"  # vpn network
        ];

      in concatStringsSep "\n" (

        # Only allow UDP DNS traffic from local IP ranges
        map ( range: "iptables -A INPUT -p udp --dport ${dnsPort} -s ${range} -j ACCEPT" ) localRanges ++
        [ "iptables -A INPUT -p udp --dport ${dnsPort} -j DROP" ] ++

        # Only allow TCP DNS traffic from local IP ranges
        map ( range: "iptables -A INPUT -p tcp --dport ${dnsPort} -s ${range} -j ACCEPT" ) localRanges ++
        [ "iptables -A INPUT -p tcp --dport ${dnsPort} -j DROP" ] ++

        # Only allow TCP HTTP traffic from local IP ranges
        map ( range: "iptables -A INPUT -p tcp --dport ${httpPort} -s ${range} -j ACCEPT" ) localRanges ++
        [ "iptables -A INPUT -p tcp --dport ${httpPort} -j DROP" ]

      );
    };

    # services.redis.servers.blocky = {
    #   enable = true;
    #   openFirewall = true;
    #   port = 6379;
    #   bind = null;
    #   databases = 16;
    #   settings.protected-mode = "no";
    # };

    services.blocky = {
      settings = {

        ports = {
          dns = cfg.dnsPort;
          http = cfg.httpPort;
        };

        # redis = {
        #   address = "127.0.0.1:6379";
        #   password = "blocky";
        #   connectionAttempts = 10;
        #   connectionCooldown = "5s";
        # };

        prometheus = {
          enable = true;
          path = "/metrics";
        };

        upstreams = {
          init.strategy = "fast";
          groups.default = [
            "https://dns.quad9.net/dns-query"
            "https://one.one.one.one/dns-query"
          ];
        };
        bootstrapDns = [{
          upstream = "https://dns.quad9.net/dns-query";
          ips = [ "9.9.9.9" "149.112.112.112" ];
        }];
        connectIPVersion = "v4";

        # Combine mappings from networks directory and Traefik configurations
        customDNS = {
          mapping = this.mapping // cfg.mapping;
          filterUnmappedTypes = true;
          customTTL = "1h";
        };

        blocking = {
          loading = {
            strategy = "fast";
            concurrency = 8;
            refreshPeriod = "4h";
          };
          blackLists = {
            main = [ 
              "${cfg.dataDir}/blacklist.txt"
              "${cfg.dataDir}/nsfw.txt"
              "https://raw.githubusercontent.com/suderman/nixos/main/modules/blocky/blacklist.txt"
            ];
          };
          whiteLists = {
            main = [
              "${cfg.dataDir}/whitelist.txt"
              "${cfg.dataDir}/whitelist-optional.txt"
              "https://raw.githubusercontent.com/suderman/nixos/main/modules/blocky/whitelist.txt"
            ];
          };
          blockTTL = "1m";
          blockType = "zeroIp";
          clientGroupsBlock = {
            default = [ "main" ];
          };
        };
      };
    };

  };

}
