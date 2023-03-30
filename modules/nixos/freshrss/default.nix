# services.freshrss.enable = true;
{ config, lib, pkgs, user, ... }:

with config.networking;

let

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

  cfg = config.services.freshrss;
  host = "freshrss.${config.networking.fqdn}";
  secrets = config.age.secrets;
  # port = "8095"; appPort = "8096";


in {



  config = mkIf cfg.enable {

    # # traefik proxy serving nginx proxy
    # services.traefik.dynamicConfigOptions.http = {
    #   routers.tandoor = {
    #     rule = "Host(`${host}`)";
    #     middlewares = mkIf (!isPublic) "local@file";
    #     tls.domains = mkIf (isPublic) [{ main = "${host}"; sans = "*.${host}"; }];
    #     tls.certresolver = "resolver-dns";
    #     service = "tandoor";
    #   };
    #   services.tandoor.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    # };

    services.freshrss = {

      defaultUser = user;
      passwordFile = secrets.password.path;

      baseUrl = "https://${host}";
      virtualHost = null; # Disable auto-generated nginx entry

      database.type = "pgsql";
      # database.host = "/var/run/postgresql";
      database.host = "127.0.0.1";
      # database.port = null;
      # database.name = "freshrss";
      # database.user = "freshrss";

    };

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
