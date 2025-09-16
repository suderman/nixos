# services.prometheus.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.prometheus;
  inherit (config.services.prometheus) exporters;
  inherit (lib) mkIf mkOption types;
in {
  options.services.prometheus = {
    name = mkOption {
      type = types.str;
      default = "prometheus";
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      retentionTime = "30d";
      webExternalUrl = "https://${cfg.name}.${config.networking.hostName}";

      exporters.node = {
        enable = true;
        port = 9100; # default 9100 overlaps with OCIS (not in use anymore)
        enabledCollectors = ["systemd"];
      };

      # https://github.com/prometheus/prometheus/wiki/Default-port-allocations
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {targets = ["127.0.0.1:${toString exporters.node.port}"];}
          ];
        }
      ];
    };

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}"; # 9090
    };
  };
}
