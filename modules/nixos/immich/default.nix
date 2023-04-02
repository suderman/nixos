# services.immich.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.services.immich;
  secrets = config.age.secrets;

  host = "immich.${config.networking.fqdn}";
  stateDir = "/var/lib/immich";

  uid = toString config.ids.uids.immich;
  gid = toString config.ids.gids.immich;

  # immich-web:3000
  # immich-server:3001
  # immich-microservices:3002
  # immich-machine-learning:3003
  redisPort = 31640;

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (builtins) toString;

in {

  # Inspiration from:
  # https://github.com/kradalby/dotfiles/blob/9caed5967db7afd67c79fe0d8649a2ff98b0a26b/machines/core.terra/immich.nix
  options = {
    services.immich.enable = lib.options.mkEnableOption "immich"; 
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
      home = "${stateDir}";
      uid = config.ids.uids.immich;
    };
    users.groups.immich.gid = config.ids.gids.immich;

    # Reverse proxy
    services.traefik.dynamicConfigOptions.http = {
      routers = {
        immich-server = {
          rule = "Host(`${host}`) && PathPrefix(`/api`)";
          middlewares = [ "local@file" "immich-server@file" ];
          tls.certresolver = "resolver-dns";
          service = "immich-server";
        };
        immich-web = {
          rule = "Host(`${host}`)";
          middlewares = "local@file";
          tls.certresolver = "resolver-dns";
          service = "immich-web";
        };
      };
      middlewares = {
        immich-server.stripPrefix.prefixes = [ "/api" ];
      };
      services = {
        immich-server.loadBalancer.servers = [{ url = "http://127.0.0.1:3001"; }];
        immich-web.loadBalancer.servers = [{ url = "http://127.0.0.1:3000"; }];
      };
    };


    # Immich docker containers
    virtualisation.oci-containers.containers = let 

      # https://github.com/immich-app/immich/releases
      version = "1.52.1";

      # Shared configuration
      base = {
        environment = {
          NODE_ENV = "production";
          DB_HOSTNAME = "127.0.0.1";
          DB_PORT = toString config.services.postgresql.port;
          DB_USERNAME = "immich";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "127.0.0.1";
          REDIS_PORT = toString config.services.redis.servers.immich.port;
          TYPESENSE_ENABLED = "false";
          REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";
          # PUID = uid;
          # PGID = gid;
        };
        # only secrets need to be included, e.g. DB_PASSWORD, TYPESENSE_API_KEY, MAPBOX_KEY
        environmentFiles = [ secrets.immich-env.path ];
        entrypoint = "/bin/sh";
        extraOptions = [
          "--network=host"
          "--add-host=immich-server:127.0.0.1"
          "--add-host=immich-microservices:127.0.0.1"
          "--add-host=immich-machine-learning:127.0.0.1"
          "--add-host=immich-web:127.0.0.1"
        ];
      };

    in {

      immich-web = base // {
        image = "altran1502/immich-web:v${version}";
        cmd = [ "./entrypoint.sh" ];
      };

      immich-server = base // {
        image = "altran1502/immich-server:v${version}";
        cmd = [ "./start-server.sh" ];
        # user = "${uid}:${gid}";
        volumes = [ "${stateDir}:/usr/src/app/upload" ];
      };

      # https://github.com/immich-app/immich/issues/776#issuecomment-1271459885
      immich-microservices = base // {
        image = "altran1502/immich-server:v${version}";
        cmd = [ "./start-microservices.sh" ];
        # user = "${uid}:${gid}";
        volumes = [ 
          "${stateDir}:/usr/src/app/upload" 
          "${stateDir}/geocoding:/usr/src/app/geocoding"
        ];
      };

      # immich-machine-learning = base // {
      #   image = "altran1502/immich-machine-learning:v${version}";
      #   cmd = [ "./entrypoint.sh" ];
      #   # user = "${uid}:${gid}";
      #   volumes = [ "${stateDir}:/usr/src/app/upload" ];
      # };

    };

    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "immich";
        ensurePermissions = { "DATABASE immich" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "immich" ];
      authentication = lib.mkBefore ''
        host immich immich 127.0.0.1/32 md5
      '';
    };

    # Redis cache configuration
    services.redis.servers.immich = {
      enable = true;
      port = redisPort;
    };

    systemd.services.docker-immich-server = {
      requires = [ "postgresql.service" "redis-immich.service" ];
      after = [ "postgresql.service" "redis-immich.service" ];
    };

    systemd.services.docker-microservices = {
      requires = [ "postgresql.service" "redis-immich.service" ];
      after = [ "postgresql.service" "redis-immich.service" ];
    };

    systemd.services.docker-immich-machine-learning = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };

    systemd.services.immich-init = {
      enable = true;
      description = "Set up paths & database access";
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
      before = [
        "docker-immich-server.service"
        "docker-immich-microservices.service"
        "docker-immich-machine-learning.service"
        "docker-immich-web.service"
        "docker-immich-proxy.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = secrets.immich-env.path;
      };
      script = ''
        mkdir -p ${stateDir}/geocoding
        chown -R ${uid}:${gid} ${stateDir}
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql postgres \
          -c "alter user immich with password '$DB_PASSWORD'"
      '';
    };

  };

}
