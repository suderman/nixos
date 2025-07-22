# services.blocky.enable = true;
{
  config,
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  cfg = config.services.blocky;
  inherit (builtins) attrValues mapAttrs toString;
  inherit (lib) concatStringsSep flatten foldl mkIf mkOption mkForce types;

  # binary with config yaml passed as argument
  blocky = let
    format = pkgs.formats.yaml {};
  in "${lib.getExe cfg.package} --config ${format.generate "config.yaml" cfg.settings}";
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
    records = mkOption {
      type = with types; anything;
      readOnly = true;
      default = foldl (a: b: a // b) {} (
        attrValues (mapAttrs (name: host: host.config.services.traefik.records or {}) flake.nixosConfigurations)
      );
    };
  };

  # Use blocky to add custom domains and block unwanted domains
  config = mkIf cfg.enable {
    # Enable reverse proxy for api
    # https://blocky.hub/api/blocking/status
    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.httpPort}";
    };

    # Ensure directory exists for downloaded lists
    tmpfiles = {
      directories = [
        {
          target = cfg.dataDir;
          user = "blocky";
        }
      ];
      files = [
        "${cfg.dataDir}/blacklist.txt"
        "${cfg.dataDir}/blacklist-extra.txt"
        "${cfg.dataDir}/blacklist-local.txt"
        "${cfg.dataDir}/whitelist.txt"
        "${cfg.dataDir}/whitelist-extra.txt"
        "${cfg.dataDir}/whitelist-local.txt"
      ];
    };

    persist.directories = [cfg.dataDir];

    # Blocky CLI with this config baked-in
    environment.systemPackages = [
      (perSystem.self.mkScript {
        name = "blocky";
        text = "${blocky} $@";
      })
    ];

    # Force systemd service to use non-dynamic user (defined below)
    systemd.services.blocky.serviceConfig = {
      DynamicUser = mkForce false;
      User = "blocky";
      Group = "blocky";
    };
    users.users.blocky = {
      isSystemUser = true;
      description = "Blocky DNS";
      group = "blocky";
    };
    users.groups.blocky = {};

    # Blocky supports downloading lists automatically, but sometimes timeouts on slow connections.
    # Get around that by downloading these lists separately as a systemd service
    systemd.services.blocky-lists-download = {
      description = "Download copy of lists for Blocky";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig.Type = "oneshot";
      path = [pkgs.curl];
      script = ''
        # Download url, ensure non-empty before replacing existing list
        download() {
          local file="${cfg.dataDir}/''${1}.txt"
          local url="''${2}"
          curl -sl ''${url} > ''${file}.tmp
          if [[ -s ''${file}.tmp ]]; then
            mv ''${file}.tmp $file
          else
            rm ''${file}.tmp
          fi
        }

        # Pre-download these lists
        download blacklist        https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/light.txt
        download blacklist-extra  https://nsfw.oisd.nl/domainswild
        download whitelist        https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt
        download whitelist-extra  https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt
      '';
      onSuccess = ["blocky-lists-refresh.service"];
    };

    # Run this script every day
    systemd.timers.blocky-lists-download = {
      wantedBy = ["timers.target"];
      partOf = ["blocky-lists-download.service"];
      timerConfig = {
        OnCalendar = "daily";
        OnBootSec = "5min"; # run 5 minutes after boot
        Unit = "blocky-lists-download.service";
      };
    };

    # Ensure permissions and refresh blocky's lists
    systemd.services.blocky-lists-refresh = {
      after = ["blocky.service"];
      requires = ["blocky.service"];
      serviceConfig.Type = "oneshot";
      script = ''
        chown blocky:blocky ${cfg.dataDir}/*.txt
        ${blocky} lists refresh
      '';
    };

    # Watch local lists for changes
    systemd.paths = let
      unit = {wantedBy = ["paths.target"];};
    in {
      blocky-lists-blacklist =
        unit
        // {
          pathConfig.PathChanged = "${cfg.dataDir}/blacklist-local.txt";
          pathConfig.Unit = "blocky-lists-refresh.service";
        };
      blocky-lists-whitelist =
        unit
        // {
          pathConfig.PathChanged = "${cfg.dataDir}/whitelist-local.txt";
          pathConfig.Unit = "blocky-lists-refresh.service";
        };
    };

    # Use local blocky for DNS queries
    networking.nameservers = ["127.0.0.1"];

    # Public firewall rules
    networking.firewall =
      if cfg.public == true
      then {
        allowedTCPPorts = [cfg.dnsPort cfg.httpPort];
        allowedUDPPorts = [cfg.dnsPort];

        # Private firewall rules (default)
      }
      else {
        extraCommands = let
          dnsPort = toString cfg.dnsPort;
          httpPort = toString cfg.httpPort;

          # We only want blocky to be available to local and VPN requests
          localRanges = [
            "127.0.0.1/32" # local host
            "192.168.0.0/16" # local network
            "10.0.0.0/8" # local network
            "172.16.0.0/12" # docker network
            "100.64.0.0/10" # vpn network
          ];
        in
          concatStringsSep "\n" (
            # Only allow UDP DNS traffic from local IP ranges
            map (range: "iptables -A INPUT -p udp --dport ${dnsPort} -s ${range} -j ACCEPT") localRanges
            ++ ["iptables -A INPUT -p udp --dport ${dnsPort} -j DROP"]
            ++
            # Only allow TCP DNS traffic from local IP ranges
            map (range: "iptables -A INPUT -p tcp --dport ${dnsPort} -s ${range} -j ACCEPT") localRanges
            ++ ["iptables -A INPUT -p tcp --dport ${dnsPort} -j DROP"]
            ++
            # Only allow TCP HTTP traffic from local IP ranges
            map (range: "iptables -A INPUT -p tcp --dport ${httpPort} -s ${range} -j ACCEPT") localRanges
            ++ ["iptables -A INPUT -p tcp --dport ${httpPort} -j DROP"]
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
        bootstrapDns = [
          {
            upstream = "https://dns.quad9.net/dns-query";
            ips = ["9.9.9.9" "149.112.112.112"];
          }
        ];
        connectIPVersion = "v4";

        # Combine records mappings from networks directory and Traefik configurations
        customDNS = {
          mapping = flake.networking.records // cfg.records;
          filterUnmappedTypes = true;
          customTTL = "1h";
        };

        blocking = {
          loading = {
            strategy = "fast";
            concurrency = 8;
            refreshPeriod = "4h";
          };
          denylists = {
            main = [
              "${cfg.dataDir}/blacklist.txt"
              "${cfg.dataDir}/blacklist-extra.txt"
              "https://raw.githubusercontent.com/suderman/nixos/main/modules/blocky/blacklist.txt"
              "${cfg.dataDir}/blacklist-local.txt"
            ];
          };
          allowlists = {
            main = [
              "${cfg.dataDir}/whitelist.txt"
              "${cfg.dataDir}/whitelist-extra.txt"
              "https://raw.githubusercontent.com/suderman/nixos/main/modules/blocky/whitelist.txt"
              "${cfg.dataDir}/whitelist-local.txt"
            ];
          };
          blockTTL = "1m";
          blockType = "zeroIp";
          clientGroupsBlock = {
            default = ["main"];
          };
        };
      };
    };

    services.prometheus = {
      scrapeConfigs = [
        {
          job_name = "blocky";
          static_configs = [
            {targets = ["127.0.0.1:${toString cfg.httpPort}"];}
          ];
        }
      ];
    };
  };
}
