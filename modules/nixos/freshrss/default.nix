# services.freshrss.enable = true;
{ config, lib, pkgs, user, ... }:

let

  inherit (lib) mkIf;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;

  cfg = config.services.freshrss;
  host = "freshrss.${config.networking.fqdn}";
  secrets = config.age.secrets;
  port = toString config.services.nginx.defaultHTTPListenPort;

in {

  config = mkIf cfg.enable {

    # traefik proxy serving nginx proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.freshrss = {
        rule = "Host(`${host}`)";
        tls.certresolver = "resolver-dns";
        middlewares = [ "local@file" "freshrss@file" ];
        service = "freshrss";
      };
      middlewares.freshrss = {
        headers.customRequestHeaders.Host = "freshrss";
      };
      services.freshrss.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

    services.freshrss = {
      defaultUser = user;
      passwordFile = secrets.password.path;
      baseUrl = "https://${host}";
      virtualHost = "freshrss";
      database.type = "pgsql";
      database.host = "127.0.0.1";
      database.name = "freshrss";
      database.user = "freshrss";
    };

    # services.nginx.virtualHosts."freshrss".listen = [
    #   { port = (toInt port); addr="127.0.0.1"; ssl = false; }
    # ];

    systemd.services.freshrss = {

      # Secret environment variables (SMTP credentials)
      serviceConfig.EnvironmentFile = secrets.smtp-env.path; 

      # Database should be running before this service starts
      after = [ "postgresql.service" ];

      # Reverse proxy should wait until after this service starts
      before = [ "nginx.service" ];

      # If the db or proxy goes down, take down this service too
      requires = [ "postgresql.service" "nginx.service" ];

    };

    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "freshrss";
        ensurePermissions = { "DATABASE freshrss" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "freshrss" ];
    };

    # Allow freshrss user to read password file
    users.users.freshrss.extraGroups = [ "secrets" ]; 

  };

}
