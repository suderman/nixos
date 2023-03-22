# services.tandoor-recipes.enable = true;
{ config, lib, pkgs, ... }:

with config.networking;

let

  cfg = config.services.tandoor-recipes;
  secrets = config.age.secrets;

  isPublic = if cfg.public == "" then false else true;
  host = if isPublic then cfg.public else "tandoor.${hostName}.${domain}";
  port = "8090"; appPort = "8091";

  inherit (lib) mkIf mkOption types strings;

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
    services.nginx.enable = true;
    services.nginx.virtualHosts."tandoor" = {
      listen = [{ port = (strings.toInt port); addr="127.0.0.1"; ssl = false; }];
      extraConfig = ''
        location /media/recipes/ {
          alias /run/nginx/recipes/;
        }
        location / {
          proxy_pass http://127.0.0.1:${appPort};
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header Host ${host};
        }
      '';
    };

    # Ensure recipes directory exists
    # tandoor_recipes uid/gid = 63528
    system.activationScripts.mkRecipesDir = lib.stringAfter [ "users" ] ''
      mkdir -p /var/lib/private/tandoor-recipes/recipes
      chown -R 63528:63528 /var/lib/private/tandoor-recipes
    '';

    # Bind mount of private recipes directory to a location accessible for nginx
    systemd.services.nginx.serviceConfig.BindPaths = [
      "/var/lib/private/tandoor-recipes/recipes:/run/nginx/recipes"
    ];

    # Tandoor port
    services.tandoor-recipes.port = strings.toInt appPort;

    # Environment variable configuration
    services.tandoor-recipes.extraConfig = {
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

    # Include SMTP environment variables
    systemd.services.tandoor-recipes.serviceConfig = {
      EnvironmentFile = secrets.smtp-env.path;
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

    # Ensure the database is brought up first
    systemd.services.tandoor-recipes.after = [ "postgresql.service" ];
    systemd.services.tandoor-recipes.requires = [ "postgresql.service" ];

  };

}
