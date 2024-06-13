# modules.radarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.radarr;
  arr = "radarr";
  inherit (config.services.prometheus) exporters;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.radarr = {
    enable = options.mkEnableOption "radarr"; 
    name = mkOption {
      type = types.str; 
      default = "radarr";
    };
    port = mkOption {
      type = types.port;
      default = 7878; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/${arr}"; 
    };
  };

  config = mkIf cfg.enable {

    services.radarr = {
      enable = true;
      user = "radarr";
      group = "media";
      package = pkgs.radarr;
      dataDir = cfg.dataDir;
    };

    users.groups.media.members = [ config.services.radarr.user ];

    modules.traefik = { 
      enable = true;
      routers."${cfg.name}" = "http://127.0.0.1:${toString cfg.port}";
    };

    services.prometheus = {
      exporters."exportarr-${arr}" = {
        enable = true;
        port = 9707;
        environment.CONFIG = "${cfg.dataDir}/config.xml";
        inherit (config.services."${arr}") user group;
      };
      scrapeConfigs = [{ 
        job_name = arr; static_configs = [ 
          { targets = [ "127.0.0.1:${toString exporters."exportarr-${arr}".port}" ]; } 
        ]; 
      }];
    };

    systemd.services = let 
      xml = "${toString cfg.dataDir}/config.xml"; 
      port = toString cfg.port; 
    in {
      "${arr}-config" = {
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
          sed -i "s|<Port>[0-9]\+</Port>|<Port>${port}</Port>|" ${xml}.txt
          sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>$(cat /etc/machine-id)</ApiKey>|" ${xml}.txt

          # Check if these attempted changes have modified the hash
          updated_hash=$(sha256sum ${xml}.txt)
          if [[ "$initial_hash" != "$updated_hash" ]]; then

            # If so, stop the service, replace the config, and start the service again
            systemctl stop ${arr}.service  
            mv ${xml}.txt ${xml}
            systemctl start ${arr}.service  

          fi
        '';
        wantedBy = [ "${arr}.service" ];
        after = [ "${arr}.service" ];
      };

      # Extend exporter to require service
      "prometheus-exportarr-${arr}-exporter" = {
        requires = [ "${arr}.service" ];
        after = [ "${arr}.service" ];
      };

    };

  };

}
