# https://github.com/elohmeier/ptsd/blob/master/1systems/htz1/modules/monica.nix
{ config, lib, pkgs, ... }:

with lib;
let
  dataDir = "/var/lib/monica";

  package = pkgs.monica.override { storagePath = "${dataDir}/storage"; };

  inherit (config.services.nginx) user;
  inherit (config.services.nginx) group;

  # see https://github.com/monicahq/monica/blob/master/docs/installation/providers/generic.md#prerequisites
  phpPackage = pkgs.php.withExtensions ({ all, ... }: with all;[
    bcmath
    curl
    fileinfo
    filter
    gd
    gmp
    iconv
    intl
    mbstring
    mysqli
    opcache
    openssl
    pdo
    pdo_mysql
    redis
    session
    sodium
    tokenizer
    xmlwriter
    zip
  ]);

  phpEnv = {
    APP_ENV = "production";
    APP_DEBUG = "\"false\"";
    #APP_KEY = "$APP_KEY";
    APP_KEY = "dummydummydummydummydummydummydu";
    APP_STORAGE_PATH = "${dataDir}/storage";
    APP_SERVICES_CACHE = "${dataDir}/cache/services.php";
    APP_PACKAGES_CACHE = "${dataDir}/cache/packages.php";
    APP_CONFIG_CACHE = "${dataDir}/cache/config.php";
    APP_ROUTES_CACHE = "${dataDir}/cache/routes-v7.php";
    APP_EVENTS_CACHE = "${dataDir}/cache/events.php";
    HASH_SALT = "$HASH_SALT";
    HASH_LENGTH = "18";
    APP_URL = "https://${config.ptsd.tailscale.fqdn}:${toString config.ptsd.ports.monica}";
    DB_CONNECTION = "mysql";
    DB_UNIX_SOCKET = "/var/run/mysqld/mysqld.sock";
    DB_DATABASE = "monica";
    DB_USERNAME = user;
    DB_USE_UTF8MB4 = "true";
    MAIL_DRIVER = "smtp";
    MAIL_HOST = "smtp.dd24.net";
    MAIL_PORT = "25";
    MAIL_USERNAME = "info@nerdworks.de";
    MAIL_PASSWORD = "$MAIL_PASSWORD";
    MAIL_ENCRYPTION = "TLS";
    MAIL_FROM_ADDRESS = "info@nerdworks.de";
    MAIL_FROM_NAME = "NerdCRM";
    APP_EMAIL_NEW_USERS_NOTIFICATION = "info@nerdworks.de";
    APP_DEFAULT_LOCALE = "de";
    APP_DISABLE_SIGNUP = "true";
    APP_SIGNUP_DOUBLE_OPTIN = "\"false\"";
    APP_TRUSTED_PROXIES = "*";
    APP_TRUSTED_CLOUDFLARE = "\"false\"";
    LOG_CHANNEL = "daily";
    SENTRY_SUPPORT = "\"false\"";
    CHECK_VERSION = "\"false\"";
    CACHE_DRIVER = "database";
    SESSION_DRIVER = "file";
    SESSION_LIFETIME = "120";
    QUEUE_DRIVER = "sync";
    DEFAULT_MAX_UPLOAD_SIZE = "512000";
    DEFAULT_FILESYSTEM = "public";
    MFA_ENABLED = "\"false\"";
    ALLOW_STATISTICS_THROUGH_PUBLIC_API_ACCESS = "\"false\"";
    POLICY_COMPLIANT = "\"false\"";
  };
in
{
  services.phpfpm.pools.monica = {
    inherit user;
    inherit group;

    phpOptions = ''
      date.timezone = "Europe/Berlin"
    '';

    inherit phpPackage;
    inherit phpEnv;

    settings = {
      "listen.mode" = "0660";
      "listen.owner" = user;
      "listen.group" = group;

      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 4;
      "pm.max_requests" = 500;
    };
  };

  systemd.services.phpfpm-monica.serviceConfig.EnvironmentFile = "/var/src/secrets/monica.env";

  # Uncomment for debugging purposes.
  # environment = {
  #   systemPackages = [ phpPackage ];
  #   sessionVariables = phpEnv;
  # };
  # Use `su nginx -s /run/current-system/sw/bin/bash` to switch to the nginx user.

  systemd.services."monica-init" = {
    enable = true;
    description = "Initialize Monica database and directory structure";
    requires = [ "mysql.service" ];
    after = [ "mysql.service" ];
    wantedBy = [ "phpfpm-monica.service" ];
    path = [ phpPackage ];
    environment = phpEnv;

    script = ''
      # cleanup old links
      cd "$STATE_DIRECTORY"
      ls | grep -v -e cache -e storage | xargs -r rm -r

      # link static content to state directory
      cd "${package}/share/monica/"
      for i in *; do
        if [ "$i" == "storage" ]; then
          continue;
        fi
        ln -s "${package}/share/monica/$i" "$STATE_DIRECTORY/$i"
      done

      cd "$STATE_DIRECTORY"

      # ensure writable folders
      mkdir -p cache
      mkdir -p storage/app/public
      mkdir -p storage/framework/cache
      mkdir -p storage/framework/sessions
      mkdir -p storage/framework/views

      # cleanup cache
      rm -f cache/*

      # migrate db schema
      php artisan monica:update --force -vv
    '';

    serviceConfig = {
      User = user;
      Group = group;
      ProtectHome = true;
      ProtectSystem = "full";
      Type = "oneshot";
      Restart = "no";
      StateDirectory = "monica";
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings.mysqld.bind-address = "127.0.0.1";

    ensureDatabases = [ "monica" ];
    ensureUsers = [
      {
        name = "nginx"; # authenticated via Unix socket authentication
        ensurePermissions = {
          "monica.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.mysqlBackup = {
    enable = true;
    databases = [ "monica" ];
  };

  services.nginx = {
    enable = true;

    virtualHosts = {
      monica = {
        forceSSL = true;
        listen = [{ addr = config.ptsd.tailscale.ip; port = config.ptsd.ports.monica; ssl = true; }];
        sslCertificate = "/var/lib/tailscale-cert/${config.ptsd.tailscale.fqdn}.crt";
        sslCertificateKey = "/var/lib/tailscale-cert/${config.ptsd.tailscale.fqdn}.key";

        root = "${dataDir}/public";

        locations."/" = {
          priority = 1;
          index = "index.php";
          extraConfig = ''try_files $uri $uri/ /index.php;'';
        };

        locations."~ \\.php$" = {
          extraConfig = ''
            try_files $uri $uri/ /index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param REDIRECT_STATUS 200;
            fastcgi_pass unix:${config.services.phpfpm.pools.monica.socket};
            fastcgi_param HTTPS on;
          '';
        };
      };
    };
  };
}

