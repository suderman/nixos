# services.arr.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.arr;
  inherit (lib) mapAttrsToList mkIf mkMerge toUpper;

  # Web UI and exportarr ports for each Servarr app
  servarr = {
    sonarr = {
      port = 8989;
      exporter = 9708;
    };
    radarr = {
      port = 7878;
      exporter = 9707;
    };
    lidarr = {
      port = 8686;
      exporter = 9709;
    };
  };

  scrape = name: port: {
    job_name = name;
    static_configs = [{targets = ["127.0.0.1:${toString port}"];}];
  };

  # Exporters need their app running
  requireService = name: {
    requires = ["${name}.service"];
    after = ["${name}.service"];
  };
in {
  options.services.arr.enable = lib.mkEnableOption "arr";

  config = mkIf cfg.enable (mkMerge (
    mapAttrsToList (name: app: {
      services.${name} = {
        enable = true;
        user = name;
        group = "media";
        dataDir = "/var/lib/${name}";
        settings.server.port = app.port;
      };

      # API key is the machine ID. systemd's %m is read before agenix writes
      # /etc/machine-id, so pass it through a generated environment file.
      systemd.services.${name}.serviceConfig = {
        RuntimeDirectory = name;
        EnvironmentFile = ["-/run/${name}/apikey.env"];
        ExecStartPre = pkgs.self.mkScript ''
          echo "${toUpper name}__AUTH__APIKEY=$(</etc/machine-id)" >/run/${name}/apikey.env
        '';
      };

      users.groups.media.members = [name];
      services.traefik.proxy.${name} = "http://127.0.0.1:${toString app.port}";
      persist.storage.directories = ["/var/lib/${name}"];

      services.prometheus = {
        exporters."exportarr-${name}" = {
          enable = true;
          port = app.exporter;
          url = "http://127.0.0.1:${toString app.port}";
          apiKeyFile = "/etc/machine-id";
        };
        scrapeConfigs = [(scrape name app.exporter)];
      };
      systemd.services."prometheus-exportarr-${name}-exporter" = requireService name;
    })
    servarr
    ++ [
      (let
        port = 8008; # package default is 8080
      in {
        # Generated settings are merged over the existing ini on every start
        services.sabnzbd = {
          enable = true;
          user = "sabnzbd";
          group = "media";
          configFile = null;
          settings.misc = {
            inherit port;
            host_whitelist = "sabnzbd.${config.networking.hostName}";
            api_key = "@api_key@";
            # Upstream defaults would reset these values set through the web UI
            bandwidth_max = "100M";
            bandwidth_perc = 80;
            cache_limit = "1G";
            inet_exposure = "api (full)";
            config_conversion_version = 5;
            notified_new_skin = 2;
          };
          secretValues."@api_key@" = "/etc/machine-id";
        };

        users.groups.media.members = ["sabnzbd"];

        services.traefik = {
          proxy.sabnzbd = "http://127.0.0.1:${toString port}";
          dynamicConfigOptions.http.middlewares.sabnzbd.headers = {
            accessControlAllowHeaders = "*";
          };
        };

        persist.storage.directories = ["/var/lib/sabnzbd"];

        services.prometheus = {
          exporters.sabnzbd = {
            enable = true;
            servers = [
              {
                baseUrl = "http://127.0.0.1:${toString port}";
                apiKeyFile = "/etc/machine-id";
              }
            ];
          };
          scrapeConfigs = [(scrape "sabnzbd" config.services.prometheus.exporters.sabnzbd.port)];
        };
        systemd.services.prometheus-sabnzbd-exporter = requireService "sabnzbd";
      })
    ]
  ));
}
