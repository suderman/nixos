# services.tandoor-recipes.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.tandoor-recipes;

  isPublic =
    if cfg.public == ""
    then false
    else true;
  hostName =
    if isPublic
    then cfg.public
    else cfg.hostName;
  port = "8097"; # default port 8096 conflicts with Jellyfin

  mediaDir = "/var/lib/private/tandoor-recipes/recipes";
  runDir = "/run/recipes";

  inherit (lib) mkIf mkOption mkBefore types;
  inherit (lib.strings) toInt;
in {
  options.services.tandoor-recipes = {
    hostName = mkOption {
      type = types.str;
      default = "tandoor.${config.networking.hostName}";
    };
    public = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    # traefik proxy serving nginx proxy
    services.traefik = {
      enable = true;
      dynamicConfigOptions.http = {
        routers.tandoor = {
          rule = "Host(`${hostName}`)";
          tls.certresolver = "resolver-dns";
          tls.domains = mkIf isPublic [
            {
              main = "${hostName}";
              sans = "*.${hostName}";
            }
          ];
          middlewares =
            ["tandoor@file"]
            ++ (
              if isPublic
              then []
              else ["local@file"]
            );
          service = "tandoor";
        };
        middlewares.tandoor = {
          headers.customRequestHeaders.Host = "tandoor";
        };
        services.tandoor.loadBalancer.servers = [
          {
            url = "http://127.0.0.1:${toString config.services.nginx.defaultHTTPListenPort}";
          }
        ];
      };
    };

    # nginx reverse proxy to statically host recipe images, proxy pass for python app
    services.nginx = {
      enable = true;
      virtualHosts."tandoor".extraConfig = ''
        location /media/recipes/ {
          alias ${runDir}/;
        }
        location / {
          proxy_pass http://127.0.0.1:${port};
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header Host ${hostName};
        }
      '';
    };

    # Bind mount of private recipes directory to a location accessible for nginx
    systemd.services.nginx = {
      preStart = mkBefore "mkdir -p ${runDir}";
      serviceConfig.BindPaths = ["${mediaDir}:${runDir}"];
    };

    # Persist data
    persist.storage.directories = [mediaDir];

    # Tandoor configuration
    services.tandoor-recipes = {
      # Service port
      port = toInt port;

      # Environment variable configuration
      extraConfig = {
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "/var/run/postgresql";
        POSTGRES_PORT = "5432";
        POSTGRES_USER = "tandoor_recipes";
        POSTGRES_DB = "tandoor_recipes";
        GUNICORN_MEDIA = "0";
        DEFAULT_FROM_EMAIL = "tandoor@${config.networking.domain}";
        ENABLE_SIGNUP = "0";
        ENABLE_PDF_EXPORT = "1";
      };
    };

    age.secrets.tandoor-recipes.rekeyFile = ./tandoor-recipes.age;
    systemd.services.tandoor-recipes = {
      # Secret environment variables (SMTP credentials)
      serviceConfig.EnvironmentFile = config.age.secrets.tandoor-recipes.path;

      # Ensure media directory exists (important for nginx's bind mount)
      # preStart = mkBefore "mkdir -p ${mediaDir}";

      # Database should be running before this service starts
      after = ["postgresql.service"];

      # Reverse proxy should wait until after this service starts
      before = ["nginx.service"];

      # If the db or proxy goes down, take down this service too
      requires = ["postgresql.service" "nginx.service"];
    };

    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "tandoor_recipes";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["tandoor_recipes"];
    };
  };
}
