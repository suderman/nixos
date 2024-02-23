# modules.sabnzbd.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.sabnzbd;
  arr = "sabnzbd";
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) dirOf toString;
  inherit (config.services.prometheus) exporters;

in {

  options.modules.sabnzbd = {
    enable = options.mkEnableOption "sabnzbd"; 
    name = mkOption {
      type = types.str;
      default = "sabnzbd";
    };
    port = mkOption {
      default = 8008; # package default is 8080
      type = types.port;
    };
  };

  config = mkIf cfg.enable {

    services.sabnzbd = {
      enable = true;
      user = "sabnzbd";
      group = "media";
    };

    users.groups.media.members = [ config.services.sabnzbd.user ];

    modules.traefik = { 
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

    services.prometheus = {
      exporters."${arr}" = {
        enable = true;
        servers = [{
          baseUrl = "https://127.0.0.1:${toString cfg.port}";
          apiKeyFile = "/etc/machine-id";
        }];
      };
      scrapeConfigs = [{ 
        job_name = arr; static_configs = [ 
          { targets = [ "127.0.0.1:${toString exporters."${arr}".port}" ]; } 
        ]; 
      }];
    };

    # Modify ini file with specified port and host name
    systemd.services = let
      ini = toString config.services."${arr}".configFile; 
      port = toString cfg.port; 
      host = toString "${cfg.name}.${this.hostName}"; 
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
          cp -fp ${ini} ${ini}.txt
          initial_hash=$(sha256sum ${ini}.txt)

          # Update the port, host name and api_key with /etc/machine-id
          sed -i '/^\[misc\]/,/^\[/ s/\(port\s*=\s*\)[0-9]\+/\1${port}/' ${ini}.txt
          sed -i 's/^host_whitelist\s*=.*/host_whitelist = ${host}/' ${ini}.txt
          sed -i "s/^api_key\s*=.*/api_key = $(cat /etc/machine-id)/" ${ini}.txt

          # Check if these attempted changes have modified the hash
          updated_hash=$(sha256sum ${ini}.txt)
          if [[ "$initial_hash" != "$updated_hash" ]]; then

            # If so, stop the service, replace the config, and start the service again
            systemctl stop ${arr}.service  
            mv ${ini}.txt ${ini}
            systemctl start ${arr}.service  

          fi
        '';
        wantedBy = [ "${arr}.service" ];
        after = [ "${arr}.service" ];
      };

      # Extend exporter to require service
      "prometheus-${arr}-exporter" = {
        requires = [ "${arr}.service" ];
        after = [ "${arr}.service" ];
      };

    };

  };

}
