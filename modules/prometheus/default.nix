# modules.prometheus.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.prometheus;
  inherit (config.services.prometheus) exporters;
  inherit (lib) mkIf mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.prometheus = {
    enable = options.mkEnableOption "prometheus"; 
    name = mkOption {
      type = types.str;
     default = "prometheus";
    };
    port = mkOption {
      default = 9090;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {

    services.prometheus = {
      enable = true;
      port = cfg.port;
      retentionTime = "30d";
      webExternalUrl = "https://${cfg.name}.${this.hostName}";

      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
      };

      # https://github.com/prometheus/prometheus/wiki/Default-port-allocations
      scrapeConfigs = [{ 
        job_name = "node"; static_configs = [ 
          { targets = [ "127.0.0.1:${toString exporters.node.port}" ]; } 
        ]; 
      }];

    };

    modules.traefik = { 
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
