# modules.freshrss.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.freshrss;
  port = config.services.nginx.defaultHTTPListenPort;

  inherit (lib) mkIf mkOption types;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;
  inherit (config.age) secrets;

in {

  options.modules.freshrss = {

    enable = lib.options.mkEnableOption "freshrss"; 

    name = mkOption {
      type = types.str;
      default = "freshrss";
    };

  };

  config = mkIf cfg.enable {

    services.freshrss = {
      enable = true;
      defaultUser = builtins.head this.admins;
      passwordFile = secrets.password.path;
      baseUrl = "https://${cfg.name}.${this.hostName}";
      virtualHost = "freshrss";
      database.type = "pgsql";
      database.host = "127.0.0.1";
      database.name = "freshrss";
      database.user = "freshrss";
    };

    # # Extend systemd service
    # systemd.services.freshrss = {
    #
    #   # Secret environment variables (SMTP credentials)
    #   serviceConfig.EnvironmentFile = secrets.smtp-env.path; 
    #
    #   # Database should be running before this service starts
    #   after = [ "postgresql.service" ];
    #
    #   # Reverse proxy should wait until after this service starts
    #   before = [ "nginx.service" ];
    #
    #   # If the db or proxy goes down, take down this service too
    #   requires = [ "postgresql.service" "nginx.service" ];
    #
    # };

    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "freshrss";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "freshrss" ];
    };

    # Allow freshrss user to read password file
    users.users.freshrss.extraGroups = [ "secrets" ]; 

    # Enable database and reverse proxies
    modules.postgresql.enable = true;
    modules.nginx.enable = true;

    modules.traefik = { 
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString port}";
      http = {
        middlewares.freshrss.headers.customRequestHeaders.Host = "${cfg.name}.${this.hostName}";
        routers.${cfg.name}.middlewares = [ "freshrss" ];
      };
    };

  };

}
