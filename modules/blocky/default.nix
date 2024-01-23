# modules.blocky.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.blocky;
  inherit (lib) mkIf mkOption mkForce types recursiveUpdate;

in {

  options.modules.blocky = {
    enable = lib.options.mkEnableOption "blocky"; 
  };

  # Use btrbk to snapshot persistent states and home
  config = mkIf cfg.enable {

    services.blocky = {
      enable = true;
      settings = {
        ports = {
          dns = 53;
          # http = "127.0.0.1:4000";
          http = "0.0.0.0:4000";
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
