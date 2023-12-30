# modules.nextcloud.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.nextcloud;
  secrets = config.age.secrets;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.nextcloud = {
    enable = lib.options.mkEnableOption "nextcloud"; 
    hostName = mkOption {
      type = types.str;
      default = "nextcloud.${config.networking.fqdn}";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/nextcloud";
    };
  };

  config = lib.mkIf cfg.enable {

    services.nextcloud = {
      enable = true;
      hostName = cfg.hostName;
      home = cfg.dataDir;
      package = pkgs.nextcloud26;
      autoUpdateApps.enable = true;
      caching.apcu = true;
      https = true;
      config = {
        adminuser = builtins.head this.admins;
        adminpassFile = secrets.password.path;
        dbtype = "pgsql";
        dbname = "nextcloud";
        dbhost = "/run/postgresql";
        defaultPhoneRegion = "CA";
        trustedProxies = [
          "127.0.0.1/32"   # local host
          "192.168.0.0/16" # local network
          "10.0.0.0/8"     # local network
          "172.16.0.0/12"  # docker network
          "100.64.0.0/10"  # vpn network
        ];
      };
    };

    # Postgres database configuration
    services.postgresql = {
      ensureUsers = [{
        name = "nextcloud";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "nextcloud" ];
    };

    # Extend systemd service
    systemd.services.nextcloud-setup = {

      # Secret environment variables (SMTP credentials)
      serviceConfig.EnvironmentFile = secrets.smtp-env.path; 

      # Database should be running before this service starts
      after = [ "postgresql.service" ];

      # If the db goes down, take down this service too
      requires = [ "postgresql.service" ];

    };

    # traefik proxy serving nginx proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.nextcloud = {
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = [ "local@file" "nextcloud@file" ];
        service = "nextcloud";
      };
      middlewares.nextcloud = {
        headers.customRequestHeaders.Host = cfg.hostName;
      };
      services.nextcloud.loadBalancer.servers = [{  
        url = "http://127.0.0.1:${toString config.services.nginx.defaultHTTPListenPort}"; 
      }];
    };

    # Allow nextcloud user to read password file
    users.users.nextcloud.extraGroups = [ "secrets" ]; 

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik.enable = true;
    modules.nginx.enable = true;

  };

}
