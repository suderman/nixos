# modules.wallabag.enable = true;
# https://github.com/jtojnar/nixfiles/blob/0c3326906559fa3f8e876e251152f0532ab239c9/hosts/azazel/ogion.cz/bag/default.nix
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.wallabag;

  inherit (lib) mkIf mkOption types toInt;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;
  inherit (config.age) secrets;

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
      default = config.services.nginx.defaultSSLListenPort; 
    };
    package = mkOption {
      type = types.package;
      default = pkgs.wallabag; # 2.5.4
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.wallabag = 912;
    ids.gids.wallabag = 912;

    users = {
      users = {

        wallabag = {
          isSystemUser = true;
          group = "wallabag";
          description = "Wallabag daemon user";
          home = cfg.dataDir;
          uid = config.ids.uids.wallabag;
        };

      # Add admins to the wallabag group
      } // extraGroups this.admins [ "wallabag" ];

      # Create group
      groups.wallabag = {
        gid = config.ids.gids.wallabag;
      };

    };

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik.enable = true;
    modules.nginx.enable = true;

    # Enable redis service for wallabag
    services.redis.servers.wallabag.enable = true;

    # Postgres database configuration
    services.postgresql = {
      ensureUsers = [{
        name = "wallabag";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "wallabag" ];
    };

    # traefik proxy 
    services.traefik.dynamicConfigOptions.http = {
      routers.wallabag = {
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = [ "local@file" "wallabag@file" ];
        service = "wallabag";
      };
      middlewares.wallabag.headers = {
        customRequestHeaders.Host = cfg.hostName;
      };
      services.wallabag.loadBalancer.servers = [{ 
        url = "https://127.0.0.1:${toString cfg.port}"; 
      }];
    };

    # nginx server for php fpm
    services.nginx.virtualHosts."${cfg.hostName}" = {
      root = "${cfg.package}/web";
      extraConfig = ''
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
      '';
      locations."/".extraConfig = "try_files $uri /app.php$is_args$args;";
      locations."/assets".root = "${cfg.package}/app/web";
      locations."~ ^/app\\.php(/|$)".extraConfig = ''
        fastcgi_pass unix:${config.services.phpfpm.pools.wallabag.socket};
        include ${config.services.nginx.package}/conf/fastcgi.conf;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME ${cfg.package}/web/$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT ${cfg.package}/web;
        fastcgi_read_timeout 120;
        internal;
      '';
      locations."~ /(?!app)\\.php$".extraConfig = "return 404;";
    } // config.modules.nginx.ssl; # use self-signed certificates

    # make php magic happen
    services.phpfpm.pools.wallabag = with pkgs; { 
      user = "wallabag";
      phpPackage = php.withExtensions ({ enabled, all }: enabled ++ [ all.imagick all.tidy ]);
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


    # Copy paramaters.yml to /etc/wallabag
    environment.etc."wallabag/parameters.template.yml" = {
      source = ./parameters.yml;
      mode = "0644";
    };

    # Run this activation script AFTER etc & agenix
    system.activationScripts."wallabag" = let 
      dir = "/etc/wallabag";
    in lib.stringAfter [ "etc" "agenix" ] ''

      # Prepare environment variables
      PATH=$PATH:${lib.makeBinPath [ pkgs.envsubst ]}
      source "${secrets.smtp-env.path}"
      export EMAIL_HOST EMAIL_PORT EMAIL_HOST_USER EMAIL_HOST_PASSWORD SECRET_KEY
      export HOST_NAME="${cfg.hostName}"

      # Populate parameters configuration with secrets
      cat ${dir}/parameters.template.yml | envsubst > ${dir}/parameters.yml
      chown -R wallabag:nginx ${dir}
      chmod 755 ${dir}

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
            "${cfg.package}/app" 
          ];
        };

      in ''
        echo "Setting up wallabag files in ${cfg.dataDir} ..."
        cd "${cfg.dataDir}"
        rm -rf var/cache/*
        rm -f app
        ln -sf "${appDir}" app
        ln -sf ${cfg.package}/composer.{json,lock} .
        export WALLABAG_DATA="${cfg.dataDir}"
        if [ ! -f installed ]; then
          mkdir -p data
          php ${cfg.package}/bin/console --env=prod wallabag:install
          touch installed
        else
          php ${cfg.package}/bin/console --env=prod doctrine:migrations:migrate --no-interaction
        fi
        php ${cfg.package}/bin/console --env=prod cache:clear
      '';
    };

  };

}
