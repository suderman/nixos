# modules.wallabag.enable = true;
# https://github.com/jtojnar/nixfiles/blob/0c3326906559fa3f8e876e251152f0532ab239c9/hosts/azazel/ogion.cz/bag/default.nix
{ config, lib, pkgs, user, ... }:

let

  cfg = config.modules.wallabag;
  secrets = config.age.secrets;

  inherit (lib) mkIf mkOption types;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;

in {

  options.modules.wallabag = {
   enable = lib.options.mkEnableOption "wallabag"; 
    hostName = mkOption {
      type = types.str;
      default = "bag.${config.networking.fqdn}";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/wallabag";
    };
    port = mkOption {
      type = types.port;
      default = 8755; 
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.wallabag = 912;
    ids.gids.wallabag = 912;

    users.users.wallabag = {
      isSystemUser = true;
      group = "wallabag";
      description = "Wallabag daemon user";
      home = cfg.dataDir;
      uid = config.ids.uids.wallabag;
    };

    users.groups.wallabag = {
      gid = config.ids.gids.wallabag;
    };

    # Add user to the wallabag group
    users.users."${user}".extraGroups = [ "wallabag" ]; 

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik.enable = true;
    modules.nginx.enable = true;

    # Postgres database configuration
    services.postgresql = {
      ensureUsers = [{
        name = "wallabag";
        ensurePermissions = { "DATABASE wallabag" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "wallabag" ];
    };

    # traefik proxy 
    services.traefik.dynamicConfigOptions.http = {
      routers.wallabag = {
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = [ "local@file" ];
        service = "wallabag";
      };
      middlewares.wallabag = {
        headers.customRequestHeaders.Host = "wallabag";
      };
      services.wallabag.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

    # nginx server for php fpm
    services.nginx.virtualHosts."wallabag" = {
      listen = [{ addr = "0.0.0.0"; port = cfg.port; ssl = false; }];
      root = "${pkgs.wallabag}/web";
      extraConfig = ''
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
      '';
      locations."/".extraConfig = "try_files $uri /app.php$is_args$args;";
      locations."/assets".root = "${pkgs.wallabag}/app/web";
      locations."~ ^/app\\.php(/|$)".extraConfig = ''
        fastcgi_pass unix:${config.services.phpfpm.pools.wallabag.socket};
        include ${config.services.nginx.package}/conf/fastcgi.conf;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME ${pkgs.wallabag}/web/$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT ${pkgs.wallabag}/web;
        fastcgi_read_timeout 120;
        internal;
      '';
      locations."~ /(?!app)\\.php$".extraConfig = "return 404;";
    };

    # make php magic happen
    services.phpfpm.pools.wallabag = {
      user = "wallabag";
      phpPackage = pkgs.php;
      settings = {
        "env[WALLABAG_DATA]" = cfg.dataDir;
        "listen.owner" = "nginx";
        "listen.group" = "root";
        "pm" = "dynamic";
        "pm.max_children" = 5;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 3;
      };
      phpOptions = ''
        # Wallabag will crash on start-up.
        # https://github.com/wallabag/wallabag/issues/6042
        error_reporting = E_ALL & ~E_USER_DEPRECATED & ~E_DEPRECATED
      '';
    };

    # Generate the parameters file
    # https://doc.wallabag.org/en/admin/parameters.html
    environment.etc."wallabag/parameters.yml".source = pkgs.writeTextFile {
      name = "wallabag-config";
      text = builtins.toJSON {
        parameters = {

          database_driver = "pdo_pgsql";
          database_driver_class = null;
          database_host = null;
          database_port = 5432;
          database_name = "wallabag";
          database_user = "wallabag";
          database_password = null;
          database_path = null;
          database_table_prefix = null;
          database_socket = "/run/postgresql";
          database_charset = "utf8";

          mailer_transport = "smtp";
          mailer_host = "EMAIL_HOST";
          mailer_port = "EMAIL_PORT";
          mailer_user = "EMAIL_HOST_USER";
          mailer_password = "EMAIL_HOST_PASSWORD";
          mailer_encryption = "tls";
          mailer_auth_mode = "plain";

          domain_name = "https://${cfg.hostName}";
          server_name = "Wallabag";
          from_email = "noreply@${cfg.hostName}";

          twofactor_auth = true;
          twofactor_sender = "noreply@${cfg.hostName}";

          fosuser_registration = true;
          fosuser_confirmation = true;
          fos_oauth_server_access_token_lifetime = 3600;
          fos_oauth_server_refresh_token_lifetime = 1209600;

          locale = "en";
          rss_limit = 50;
          sentry_dsn = null;
          secret = "SECRET_KEY";

          rabbitmq_host = null;
          rabbitmq_port = null;
          rabbitmq_user = null;
          rabbitmq_password = null;
          rabbitmq_prefetch_count = null;

          redis_scheme = null;
          redis_host = null;
          redis_port = null;
          redis_path = null;
          redis_password = null;

        };
      };
    };

    # We use agenix so we need to modify the config at activation time
    system.activationScripts."wallabag" = let 
      sed = "${pkgs.gnused}/bin/sed";
    in lib.stringAfter [ "etc" "agenix" ] ''
      source "${secrets.smtp-env.path}"
      dir=/etc/wallabag
      mkdir -p "$dir"
      ${sed} -i "s/EMAIL_HOST/$EMAIL_HOST/" "$dir/parameters.yml"
      ${sed} -i "s/EMAIL_PORT/$EMAIL_PORT/" "$dir/parameters.yml"
      ${sed} -i "s/EMAIL_HOST_USER/$EMAIL_HOST_USER/" "$dir/parameters.yml"
      ${sed} -i "s/EMAIL_HOST_PASSWORD/$EMAIL_HOST_PASSWORD/" "$dir/parameters.yml"
      ${sed} -i "s/SECRET_KEY/$SECRET_KEY/" "$dir/parameters.yml"
      chown -R wallabag:nginx "$dir"
      chmod 755 "$dir"
    '';

    # Wallabag systemd unit
    systemd.services.wallabag = {
      description = "Wallabag install service";
      wantedBy = [ "multi-user.target" ];
      before = [ "phpfpm-wallabag.service" ];

      # Database should be running before this service starts
      after = [ "postgresql.service" ];

      # If the db goes down, take down this service too
      requires = [ "postgresql.service" ];

      path = with pkgs; [ coreutils php phpPackages.composer ];

      serviceConfig = {
        User = "wallabag";
        Type = "oneshot";
        RemainAfterExit = "yes";
        PermissionsStartOnly = true;
      };

      preStart = ''
        mkdir -p "${cfg.dataDir}"
        chown wallabag:nginx "${cfg.dataDir}"
      '';

      script = let 

        configFileLink = pkgs.runCommandLocal "wallabag-config-link" {} ''
          mkdir -p "$out/config"
          ln -s "/etc/wallabag/parameters.yml" "$out/config/parameters.yml"
        '';

        appDir = pkgs.buildEnv {
          name = "wallabag-app-dir";
          ignoreCollisions = true;
          checkCollisionContents = false;
          paths = [ 
            configFileLink
            "${pkgs.wallabag}/app" 
          ];
        };

      in ''
        echo "Setting up wallabag files in ${cfg.dataDir} ..."
        cd "${cfg.dataDir}"
        rm -rf var/cache/*
        rm -f app
        ln -sf "${appDir}" app
        ln -sf ${pkgs.wallabag}/composer.{json,lock} .
        export WALLABAG_DATA="${cfg.dataDir}"
        if [ ! -f installed ]; then
        mkdir -p data
        php ${pkgs.wallabag}/bin/console --env=prod wallabag:install
        touch installed
        else
        php ${pkgs.wallabag}/bin/console --env=prod doctrine:migrations:migrate --no-interaction
        fi
        php ${pkgs.wallabag}/bin/console --env=prod cache:clear
      '';
    };

  };

}
