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

      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-piechart-panel
        grafana-clock-panel
      ];

      settings = {
        server = {
          domain = "${cfg.name}.${this.hostName}";
          protocol = "http";
          http_port = 2342;
          http_addr = "127.0.0.1";
        };

        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
          check_for_plugin_updates = false;
        };

        panels = {
          disable_sanitize_html = true;
          enable_alpha = true;
        };

      };

      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        } {
          name = "PostgreSQL (Blocky)";
          type = "postgres";
          access = "proxy";
          url = config.networking.hostName;
          user = "blocky";
          jsonData = { user = "blocky"; database = "blocky"; sslmode = "disable"; };
        }];
        dashboards.settings.providers = [{
          name = "Nodes";
          options.path = ./provisioning/nodes.json;
        } {
          name = "systemd Service Dashboard";
          options.path = ./provisioning/systemd.json;
        } {
          name = "UPS Status";
          options.path = ./provisioning/nut.json;
        } {
          name = "ZFS Pool Status";
          options.path = ./provisioning/zfs.json;
        } {
          name = "Blocky Metrics";
          options.path = ./provisioning/blocky.json;
        } {
          name = "Blocky Queries";
          options.path = ./provisioning/blocky-queries.json;
        } {
          name = "Smokeping";
          options.path = ./provisioning/smokeping.json;
        } {
          name = "Unifi: Client Insights";
          options.path = ./provisioning/unifi/clients.json;
        } {
          name = "Unifi: Switch Insights";
          options.path = ./provisioning/unifi/switches.json;
        } {
          name = "Unifi: AP Insights";
          options.path = ./provisioning/unifi/aps.json;
        } {
          name = "Unifi: Network Site Insights";
          options.path = ./provisioning/unifi/sites.json;
        }];
      };
    };

    modules.traefik = { 
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
