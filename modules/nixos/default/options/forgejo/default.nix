{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.forgejo;
in {
  options.services.forgejo = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "forgejo";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3099;
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      package = pkgs.forgejo;
      database.type = "postgres";
      database.socket = "/run/postgresql";
      settings = {
        server = {
          DOMAIN = "${cfg.name}.${config.networking.hostName}";
          ROOT_URL = "https://${cfg.name}.${config.networking.hostName}/";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = cfg.port;
        };
        session.COOKIE_SECURE = true;
        service.DISABLE_REGISTRATION = false;
      };
    };

    persist.storage.directories = [cfg.stateDir];

    tmpfiles.directories = [
      {
        target = cfg.stateDir;
        mode = 750;
        user = cfg.user;
        group = cfg.group;
      }
    ];

    # Extend systemd service
    age.secrets.forgejo.rekeyFile = ./forgejo-env.age;
    systemd.services.forgejo = {
      # Secret environment variables (SMTP credentials, key, token, secret)
      serviceConfig.EnvironmentFile = config.age.secrets.forgejo.path;

      # Database should be running before this service starts
      after = ["postgresql.service"];

      # If the db goes down, take down this service too
      requires = ["postgresql.service"];
    };

    # Postgres database configuration
    services.postgresql.enable = true;
    # services.postgresql = {
    #   enable = true;
    #   ensureUsers = [
    #     {
    #       name = "forgejo";
    #       ensureDBOwnership = true;
    #     }
    #   ];
    #   ensureDatabases = ["forgejo"];
    # };

    # Allow forgejo user to read password file
    users.users.forgejo.extraGroups = ["secrets"];

    # Enable reverse proxy
    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
