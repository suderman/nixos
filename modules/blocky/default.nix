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
          customTTL = "1h";
          filterUnmappedTypes = true;
          mapping = this.network.mapping; 
        };

        blocking = {
          loading = {
            strategy = "fast";
            concurrency = 8;
            refreshPeriod = "4h";
          };
          blackLists = {
            ads = [
              "https://blocklistproject.github.io/Lists/ads.txt"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://adaway.org/hosts.txt"
              "https://v.firebog.net/hosts/AdguardDNS.txt"
              "https://v.firebog.net/hosts/Admiral.txt"
              "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
              "https://v.firebog.net/hosts/Easylist.txt"
              "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
              "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
            ];
            tracking = [
              "https://v.firebog.net/hosts/Easyprivacy.txt"
              "https://v.firebog.net/hosts/Prigent-Ads.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
              "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
              "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
            ];
            malicious = [
              "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
              "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
              "https://v.firebog.net/hosts/Prigent-Crypto.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
              "https://v.firebog.net/hosts/RPiList-Phishing.txt"
              "https://v.firebog.net/hosts/RPiList-Malware.txt"
            ];
            misc = [
              "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-only/hosts"
            ];
            porn = [
              "https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list"
              "https://v.firebog.net/hosts/Prigent-Adult.txt"
            ];
            catchall = [
              "https://big.oisd.nl/domainswild"
            ];
          };
          whiteLists = {
            ads = [
              "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt"
              "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt"
            ];
          };
          blockTTL = "1m";
          blockType = "zeroIp";
          clientGroupsBlock = {
            # default = [ "ads" "tracking" "malicious" "misc" "catchall" ];
            default = [ "malicious" "porn" ];
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
