# modules.sabnzbd.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.sabnzbd;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;

in {

  options.modules.sabnzbd = {
    enable = options.mkEnableOption "sabnzbd"; 
    hostName = mkOption {
      type = types.str;
      default = "sab.${config.networking.fqdn}";
      description = "FQDN for the sabnzd instance";
    };
    port = mkOption {
      description = "Port for sabnzbd instance";
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

    # Modify ini file with specified port and host name
    systemd.services.sabnzbd-ini = {
      serviceConfig = {
        User = "root";
        Type = "oneshot";
      };
      path = with pkgs; [ coreutils gnused systemd ];
      script = let 
        ini = toString config.services.sabnzbd.configFile; 
        port = toString cfg.port; 
        host = toString cfg.hostName; 
      in ''
        # Give it 5 seconds to get going
        sleep 5 

        # Make a copy of the config file and save the hash
        cp -fp ${ini} ${ini}.txt
        initial_hash=$(sha256sum ${ini}.txt)

        # Update the port and host name
        sed -i '/^\[misc\]/,/^\[/ s/\(port\s*=\s*\)[0-9]\+/\1${port}/' ${ini}.txt
        sed -i 's/^host_whitelist\s*=.*/host_whitelist = ${host}/' ${ini}.txt

        # Check if these attempted changes have modified the hash
        updated_hash=$(sha256sum ${ini}.txt)
        if [[ "$initial_hash" != "$updated_hash" ]]; then

          # If so, stop the service, replace the config, and start the service again
          systemctl stop sabnzbd.service  
          mv ${ini}.txt ${ini}
          systemctl start sabnzbd.service  

        fi
      '';
      wantedBy = [ "sabnzbd.service" ];
      after = [ "sabnzbd.service" ];
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.sabnzbd = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = "local@file";
        service = "sabnzbd";
      };
      services.sabnzbd.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
