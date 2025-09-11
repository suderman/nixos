# -- modified module --
# services.gitea.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.gitea;

  inherit (lib) mkIf mkOption types;
  inherit (config.age) secrets;
in {
  options.services.gitea = {
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
      package = pkgs.gitea;
      database.type = "postgres";
      database.socket = "/run/postgresql";
      settings = {
        server.DOMAIN = "${cfg.name}.${config.networking.hostName}";
        server.ROOT_URL = "https://${cfg.name}.${config.networking.hostName}/";
        server.HTTP_PORT = cfg.port;
        session.COOKIE_SECURE = true;
        service.DISABLE_REGISTRATION = false;
      };
    };

    # Extend systemd service
    age.secrets.gitea.rekeyFile = ./gitea.age;
    systemd.services.gitea = {
      # Secret environment variables (SMTP credentials)
      serviceConfig.EnvironmentFile = config.age.secrets.gitea.path;

      # Database should be running before this service starts
      after = ["postgresql.service"];

      # If the db goes down, take down this service too
      requires = ["postgresql.service"];
    };

    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "gitea";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["gitea"];
    };

    # Allow gitea user to read password file
    users.users.gitea.extraGroups = ["secrets"];

    # Enable reverse proxy
    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
