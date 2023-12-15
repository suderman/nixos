{ config, lib, ... }: 

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;
  inherit (builtins) toString;

in {

  # Shared environment variables for each docker container
  config.modules.immich.environment = mkIf cfg.enable {

    # immich
    NODE_ENV = "production";
    PUID = toString config.ids.uids.immich;
    PGID = toString config.ids.gids.immich;
    REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";

    # postgresql
    DB_HOSTNAME = "host.docker.internal";
    DB_PORT = toString config.services.postgresql.port;
    DB_USERNAME = "immich";
    DB_DATABASE_NAME = "immich";

    # redis
    REDIS_HOSTNAME = "immich-redis";

    # Path to secret file
    file = config.age.secrets.immich-env.path;
    # DB_PASSWORD=
    # MAPBOX_KEY=
    # JWT_SECRET=

  };

}
