# services.immich.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  secrets = config.age.secrets;

  uid = toString config.ids.uids.immich;
  gid = toString config.ids.gids.immich;

  # https://github.com/immich-app/immich/releases
  version = "1.52.1";

  # Shared configuration for each docker container
  base = {
    environment = {
      # immich
      NODE_ENV = "production";
      PUID = uid;
      PGID = gid;
      REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";
      # postgresql
      DB_HOSTNAME = "host.docker.internal";
      DB_PORT = toString cfg.dbPort;
      DB_USERNAME = "immich";
      DB_DATABASE_NAME = "immich";
      # redis
      REDIS_HOSTNAME = "immich-redis";
      # typesense
      TYPESENSE_HOST =  "immich-typesense";
      TYPESENSE_API_KEY = "1234567890";
      TYPESENSE_DATA_DIR = "/data";
    };
    # only secrets need to be included, e.g. DB_PASSWORD, TYPESENSE_API_KEY, MAPBOX_KEY
    environmentFiles = [ secrets.immich-env.path ];
    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
      "--network=immich"
    ];
  };

  # Containers will not stop gracefully, so kill it
  kill = {
    serviceConfig = {
      KillSignal = "SIGKILL";
      SuccessExitStatus = "0 SIGKILL";
    };
  };

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;

in {

  # Inspiration from:
  # https://github.com/kradalby/dotfiles/blob/9caed5967db7afd67c79fe0d8649a2ff98b0a26b/machines/core.terra/immich.nix
  options.services.immich = {

    enable = lib.options.mkEnableOption "immich"; 

    host = mkOption {
      type = types.str;
      default = "immich.${config.networking.fqdn}";
      description = "Host for Immich";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/immich";
      description = "Data directory for Immich";
    };

    webPort = mkOption {
      description = "Immich web port.";
      default = 3000;
      type = types.port;
    };

    serverPort = mkOption {
      description = "Immich server port.";
      default = 3001;
      type = types.port;
    };

    dbPort = mkOption {
      description = "Immich database port.";
      default = config.services.postgresql.port;
      type = types.port;
    };

  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.immich = 282;
    ids.gids.immich = 282;

    users.users.immich = {
      isSystemUser = true;
      group = "immich";
      description = "Immich daemon user";
      home = cfg.dataDir;
      uid = config.ids.uids.immich;
    };
    users.groups.immich.gid = config.ids.gids.immich;


    # Reverse proxy
    services.traefik.dynamicConfigOptions.http = {
      routers = {
        immich-server = {
          rule = "Host(`${cfg.host}`) && PathPrefix(`/api`)";
          middlewares = [ "local@file" "immich-server@file" ];
          tls.certresolver = "resolver-dns";
          service = "immich-server";
        };
        immich-web = {
          rule = "Host(`${cfg.host}`)";
          middlewares = "local@file";
          tls.certresolver = "resolver-dns";
          service = "immich-web";
        };
      };
      middlewares = {
        immich-server.stripPrefix.prefixes = [ "/api" ];
      };
      services = {
        immich-server.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.serverPort}"; }];
        immich-web.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.webPort}"; }];
      };
    };


    # Init service
    systemd.services.immich = {
      enable = true;
      description = "Set up paths & database access";
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
      before = [
        "docker-immich-web.service"
        "docker-immich-redis.service"
        "docker-immich-typesense.service"
        "docker-immich-machine-learning.service"
        "docker-immich-server.service"
        "docker-immich-microservices.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        EnvironmentFile = secrets.immich-env.path;
      };
      script = ''
        #
        # Ensure docker network exists
        ${pkgs.docker}/bin/docker network create immich 2>/dev/null || true
        #
        # Ensure data directory exists with expected ownership
        mkdir -p ${cfg.dataDir}/geocoding
        chown -R ${uid}:${gid} ${cfg.dataDir}
        #
        # Ensure database user has expected password
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql postgres \
          -c "alter user immich with password '$DB_PASSWORD'"
      '';
    };


    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "immich";
        ensurePermissions = { "DATABASE immich" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "immich" ];
      # Allow connections from docker container IP addresses
      authentication = lib.mkBefore ''
        host immich immich 172.17.0.0/12 md5
      '';
    };


    # Web front-end
    virtualisation.oci-containers.containers.immich-web = base // {
      image = "ghcr.io/immich-app/immich-web:v${version}";
      entrypoint = "/bin/sh";
      cmd = [ "./entrypoint.sh" ];
      ports = [ "${toString cfg.webPort}:3000" ];
    };

    systemd.services.docker-immich-web = kill // {
      requires = [ "immich.service" ];
      after = [ "immich.service" ];
    };


    # Redis cache
    virtualisation.oci-containers.containers.immich-redis = base // {
      image = "redis:6.2";
    };

    systemd.services.docker-immich-redis = {
      requires = [ "immich.service" ];
      after = [ "docker-immich-web.service" ];
    };


    # Typesense search engine
    virtualisation.oci-containers.containers.immich-typesense = base // {
      image = "typesense/typesense:0.24.0";
      volumes = [ "tsdata:/data" ];
    };

    systemd.services.docker-immich-typesense = {
      requires = [ "immich.service" ];
      after = [ "docker-immich-redis.service" ];
    };


    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = base // {
      image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload" 
        "model-cache:/cache"
      ];
    };

    systemd.services.docker-immich-machine-learning = kill // {
      requires = [ "immich.service" "docker-immich-typesense.service" "docker-immich-redis.service" "postgresql.service" ];
      after = [ "docker-immich-typesense.service" ];
    };


    # Server back-end
    virtualisation.oci-containers.containers.immich-server = base // {
      image = "ghcr.io/immich-app/immich-server:v${version}";
      entrypoint = "/bin/sh";
      cmd = [ "./start-server.sh" ];
      user = "${uid}:${gid}";
      ports = [ "${toString cfg.serverPort}:3001" ];
      volumes = [ "${cfg.dataDir}:/usr/src/app/upload" ];
    };

    systemd.services.docker-immich-server = kill // {
      requires = [ "immich.service" "docker-immich-typesense.service" "docker-immich-redis.service" "postgresql.service" ];
      after = [ "docker-immich-typesense.service" ];
    };


    # Microservices
    # https://github.com/immich-app/immich/issues/776#issuecomment-1271459885
    virtualisation.oci-containers.containers.immich-microservices = base // {
      image = "ghcr.io/immich-app/immich-server:v${version}";
      entrypoint = "/bin/sh";
      cmd = [ "./start-microservices.sh" ];
      user = "${uid}:${gid}"; 
      volumes = [ 
        "${cfg.dataDir}:/usr/src/app/upload" 
        "${cfg.dataDir}/geocoding:/usr/src/app/geocoding"
      ];
    };

    systemd.services.docker-immich-microservices = kill // {
      requires = [ "immich.service" "docker-immich-typesense.service" "docker-immich-redis.service" "postgresql.service" ];
      after = [ "docker-immich-typesense.service" ];
    };


  };

}
