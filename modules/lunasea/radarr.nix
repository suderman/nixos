{ config, lib, pkgs, ... }: let

  cfg = config.services.lunasea;
  arr = config.services.${name};
  inherit (config.services.prometheus) exporters;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

  # arrttributes
  name = "radarr";
  port = 7878;
  prometheusPort = 9707;


in {

  config = mkIf cfg.enable {

    services.${name} = {
      enable = true;
      user = name;
      group = "media";
      dataDir = "/var/lib/${name}";
    };

    users.groups.media.members = [ arr.user ];

    modules.traefik = {
      enable = true;
      routers.${name} = "http://127.0.0.1:${toString port}";
    };

    services.prometheus = {
      exporters."exportarr-${name}" = {
        enable = true;
        port = prometheusPort;
        environment.CONFIG = "${arr.dataDir}/config.xml";
        inherit (arr) user group;
      };
      scrapeConfigs = [{ 
        job_name = name; static_configs = [ 
          { targets = [ "127.0.0.1:${toString exporters."exportarr-${name}".port}" ]; } 
        ]; 
      }];
    };

    # Modify config.xml with specified port and apikey
    systemd.services = let xml = "${toString arr.dataDir}/config.xml"; in {

      "${name}-config" = {
        serviceConfig = {
          User = "root";
          Type = "oneshot";
        };
        path = with pkgs; [ coreutils gnused systemd ];
        script = ''
          # Give it 5 seconds to get going
          sleep 5 

          # Make a copy of the config file and save the hash
          cp -fp ${xml} ${xml}.txt
          initial_hash=$(sha256sum ${xml}.txt)

          # Update the port and apikey with /etc/machine-id
          sed -i "s|<Port>[0-9]\+</Port>|<Port>${toString port}</Port>|" ${xml}.txt
          sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>$(cat /etc/machine-id)</ApiKey>|" ${xml}.txt

          # Check if these attempted changes have modified the hash
          updated_hash=$(sha256sum ${xml}.txt)
          if [[ "$initial_hash" != "$updated_hash" ]]; then

            # If so, stop the service, replace the config, and start the service again
            systemctl stop ${name}.service  
            mv ${xml}.txt ${xml}
            systemctl start ${name}.service  

          fi
        '';
        wantedBy = [ "${name}.service" ];
        after = [ "${name}.service" ];
      };

      # Extend exporter to require service
      "prometheus-exportarr-${name}-exporter" = {
        requires = [ "${name}.service" ];
        after = [ "${name}.service" ];
      };

    };

  };

}
