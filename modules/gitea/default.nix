# modules.gitea.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.gitea;

  inherit (lib) mkIf mkOption types;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;
  inherit (config.age) secrets;

in {

  options.modules.gitea = {
    enable = lib.options.mkEnableOption "gitea"; 
    name = mkOption {
      type = types.str;
      default = "gitea";
    };
    port = mkOption {
      type = types.port;
      default = 3099; 
    };
  };

  config = mkIf cfg.enable {

    services.gitea = {
      enable = true;
      package = pkgs.gitea;
      database.type = "postgres";
      database.socket = "/run/postgresql";
      settings = {
        server.DOMAIN = "${cfg.name}.${this.hostName}";
        server.ROOT_URL = "https://${cfg.name}.${this.hostName}/";
        server.HTTP_PORT = cfg.port;
        session.COOKIE_SECURE = true;
        service.DISABLE_REGISTRATION = false;
      };
    };

    # Extend systemd service
    systemd.services.gitea = {

      # Secret environment variables (SMTP credentials)
      serviceConfig.EnvironmentFile = secrets.smtp-env.path; 

      # Database should be running before this service starts
      after = [ "postgresql.service" ];

      # If the db goes down, take down this service too
      requires = [ "postgresql.service" ];

    };

    # Postgres database configuration
    services.postgresql = {
      ensureUsers = [{
        name = "gitea";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "gitea" ];
    };

    # Allow gitea user to read password file
    users.users.gitea.extraGroups = [ "secrets" ]; 

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
