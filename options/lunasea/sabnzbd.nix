{ config, lib, pkgs, this, ... }: let

  cfg = config.services.lunasea;
  arr = config.services.${name};
  inherit (config.services.prometheus) exporters;
  inherit (lib) mkBefore mkIf mkOption options types;
  inherit (builtins) toString;

  # arrttributes
  name = "sabnzbd";
  port = 8008; # package default is 8080

in {

  config = mkIf cfg.enable {

    services.${name} = {
      enable = true;
      user = name;
      group = "media";
    };

    users.groups.media.members = [ arr.user ];

    services.traefik = {
      proxy.${name} = "http://127.0.0.1:${toString port}";
      dynamicConfigOptions.http.middlewares.${name}.headers = {
        accessControlAllowHeaders = "*";
      };
    };

    services.prometheus = {
      exporters."${name}" = {
        enable = true;
        servers = [{
          baseUrl = "https://127.0.0.1:${toString port}";
          apiKeyFile = "/etc/machine-id";
        }];
      };
      scrapeConfigs = [{ 
        job_name = name; static_configs = [ 
          { targets = [ "127.0.0.1:${toString exporters."${name}".port}" ]; } 
        ]; 
      }];
    };

    # Modify ini file with specified port and host name
    systemd.services = let
      ini = toString arr.configFile; 
      host = toString "${name}.${this.hostName}"; 
    in {

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
          cp -fp ${ini} ${ini}.txt
          initial_hash=$(sha256sum ${ini}.txt)

          # Update the port, host name and api_key with /etc/machine-id
          sed -i '/^\[misc\]/,/^\[/ s/\(port\s*=\s*\)[0-9]\+/\1${toString port}/' ${ini}.txt
          sed -i 's/^host_whitelist\s*=.*/host_whitelist = ${host}/' ${ini}.txt
          sed -i "s/^api_key\s*=.*/api_key = $(cat /etc/machine-id)/" ${ini}.txt

          # Check if these attempted changes have modified the hash
          updated_hash=$(sha256sum ${ini}.txt)
          if [[ "$initial_hash" != "$updated_hash" ]]; then

            # If so, stop the service, replace the config, and start the service again
            systemctl stop ${name}.service  
            mv ${ini}.txt ${ini}
            systemctl start ${name}.service  

          fi
        '';
        wantedBy = [ "${name}.service" ];
        after = [ "${name}.service" ];
      };

      # Extend exporter to require service
      "prometheus-${name}-exporter" = {
        requires = [ "${name}.service" ];
        after = [ "${name}.service" ];
      };

    };

  };

}
