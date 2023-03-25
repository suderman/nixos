# services.tandoor-recipes.enable = true;
{ config, lib, pkgs, ... }:

with config.networking;

let

  cfg = config.services.tandoor-recipes;
  secrets = config.age.secrets;

  isPublic = if cfg.public == "" then false else true;
  host = if isPublic then cfg.public else "tandoor.${hostName}.${domain}";
  port = "8095"; appPort = "8096";

  mediaDir = "/var/lib/private/tandoor-recipes/recipes";
  runDir = "/run/recipes";

  inherit (lib) mkIf mkOption mkBefore types;
  inherit (lib.strings) toInt;

in {

  options.services.tandoor-recipes.public = mkOption { type = types.str; default = ""; };

  config = mkIf cfg.enable {

    # traefik proxy serving nginx proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.tandoor = {
        rule = "Host(`${host}`)";
        middlewares = mkIf (!isPublic) "local@file";
        tls.domains = mkIf (isPublic) [{ main = "${host}"; sans = "*.${host}"; }];
        tls.certresolver = "resolver-dns";
        service = "tandoor";
      };
      services.tandoor.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

    # nginx reverse proxy to statically host recipe images, proxy pass for python app
    services.nginx = {
      enable = true;
      virtualHosts."tandoor" = {
        listen = [{ port = (toInt port); addr="127.0.0.1"; ssl = false; }];
        extraConfig = ''
          location /media/recipes/ {
            alias ${runDir}/;
          }
          location / {
            proxy_pass http://127.0.0.1:${appPort};
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header Host ${host};
          }
        '';
      };
    };

    # Bind mount of private recipes directory to a location accessible for nginx
    systemd.services.nginx = {
      preStart = mkBefore "mkdir -p ${runDir}";
      serviceConfig.BindPaths = [ "${mediaDir}:${runDir}" ];
    };

    # Tandoor configuration
    services.tandoor-recipes = {

      # Service port
      port = toInt appPort;

      # Environment variable configuration
      extraConfig = {
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "/var/run/postgresql";
        POSTGRES_PORT = "5432";
        POSTGRES_USER = "tandoor_recipes";
        POSTGRES_DB = "tandoor_recipes";
        GUNICORN_MEDIA = "0";
        DEFAULT_FROM_EMAIL = "tandoor@${domain}";
        ENABLE_SIGNUP = "0";
        ENABLE_PDF_EXPORT = "1";
      };

    };

    systemd.services.tandoor-recipes = {

      # Secret environment variables (SMTP credentials)
      serviceConfig.EnvironmentFile = secrets.smtp-env.path; 

      # Ensure media directory exists (important for nginx's bind mount)
      preStart = mkBefore "mkdir -p ${mediaDir}"; 

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
        name = "tandoor_recipes";
        ensurePermissions = { "DATABASE tandoor_recipes" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "tandoor_recipes" ];
    };


  };

}
