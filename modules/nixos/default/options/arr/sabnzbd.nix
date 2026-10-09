{
  config,
  lib,
  ...
}: let
  cfg = config.services.arr;
  arr = config.services.${name};
  inherit (config.services.prometheus) exporters;
  inherit (lib) mkIf;

  # arrttributes
  name = "sabnzbd";
  port = 8008; # package default is 8080
in {
  config = mkIf cfg.enable {
    # Generated settings are merged over the existing ini on every start
    services.${name} = {
      enable = true;
      user = name;
      group = "media";
      configFile = null;
      settings.misc = {
        inherit port;
        host_whitelist = "${name}.${config.networking.hostName}";
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

    users.groups.media.members = [arr.user];

    services.traefik = {
      proxy.${name} = "http://127.0.0.1:${toString port}";
      dynamicConfigOptions.http.middlewares.${name}.headers = {
        accessControlAllowHeaders = "*";
      };
    };

    # Persist data between reboots
    persist.storage.directories = ["/var/lib/sabnzbd"];

    services.prometheus = {
      exporters."${name}" = {
        enable = true;
        servers = [
          {
            baseUrl = "http://127.0.0.1:${toString port}";
            apiKeyFile = "/etc/machine-id";
          }
        ];
      };
      scrapeConfigs = [
        {
          job_name = name;
          static_configs = [
            {targets = ["127.0.0.1:${toString exporters."${name}".port}"];}
          ];
        }
      ];
    };

    # Extend exporter to require service
    systemd.services."prometheus-${name}-exporter" = {
      requires = ["${name}.service"];
      after = ["${name}.service"];
    };
  };
}
