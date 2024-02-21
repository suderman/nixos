# modules.grafana.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.grafana;
  inherit (lib) mkIf mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.grafana = {
    enable = options.mkEnableOption "grafana"; 
    name = mkOption {
      type = types.str;
      default = "grafana";
    };
    port = mkOption {
      default = 2342;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {

    services.grafana = {
      enable = true;
      declarativePlugins = with pkgs.grafanaPlugins; [ grafana-clock-panel ];
      settings = {
        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
          check_for_plugin_updates = false;
        };
        security.disable_gravatar = true;
        panels.disable_sanitize_html = true;
        server = {
          domain = "${cfg.name}.${this.hostName}";
          protocol = "http";
          http_port = 2342;
          http_addr = "0.0.0.0";
          enable_gzip = true; # recommended for perf, change if compat is bad
        };
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }];
      };
    };

    modules.traefik = { 
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
