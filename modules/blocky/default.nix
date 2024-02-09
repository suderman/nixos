# modules.blocky.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.blocky;
  inherit (lib) mkIf mkOption mkForce types;

in {

  options.modules.blocky = {
    enable = lib.options.mkEnableOption "blocky"; 
    name = mkOption {
      type = types.str;
      default = "blocky";
    };
  };

  # Use btrbk to snapshot persistent states and home
  config = mkIf cfg.enable {

    # Enable reverse proxy for api
    # https://blocky.hub/api/blocking/status
    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:4000";
    };

    services.redis.servers.blocky = {
      enable = true;
      openFirewall = true;
      port = 6379;
      bind = null;
      databases = 16;
      settings.protected-mode = "no";
    };

    services.blocky = {
      enable = true;
      settings = {

        ports = {
          dns = 53;
          # http = "127.0.0.1:4000";
          http = "0.0.0.0:4000";
        };

        redis = {
          # address = "hub:6379";
          address = "127.0.0.1:6379";
          password = "blocky";
          connectionAttempts = 10;
          connectionCooldown = "5s";
          # sentinelAddresses = [ "eve:26379" ];
        };

        connectIPVersion = "v4";
        upstream.default = [
          "https://dns.quad9.net/dns-query"
          "https://one.one.one.one/dns-query"
        ];

        bootstrapDns = [{
          upstream = "https://dns.quad9.net/dns-query";
          ips = [ "9.9.9.9" "149.112.112.112" ];
        }];

        customDNS = {
          inherit (this.network) mapping;
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
              "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/light.txt" 
              "https://nsfw.oisd.nl/domainswild"
              "https://raw.githubusercontent.com/suderman/nixos/main/modules/blocky/blacklist.nix"
            ];
          };
          whiteLists = {
            main = [
              "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt"
              "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt"
              "https://raw.githubusercontent.com/suderman/nixos/main/modules/blocky/whitelist.nix"
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

    networking.firewall = {
      allowedTCPPorts = [
        config.services.blocky.settings.ports.dns
        4000
        # config.services.grafana.settings.server.http_port
      ];
      allowedUDPPorts = [
        config.services.blocky.settings.ports.dns
      ];
    };

  };

}
