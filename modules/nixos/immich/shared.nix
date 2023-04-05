{ config }: {

  # https://github.com/immich-app/immich/releases
  version = "1.52.1";

  uid = builtins.toString config.ids.uids.immich;
  gid = builtins.toString config.ids.gids.immich;

  # Shared environment variables for each docker container
  environment = {

    # immich
    NODE_ENV = "production";
    PUID = builtins.toString config.ids.uids.immich;
    PGID = builtins.toString config.ids.gids.immich;
    REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";

    # postgresql
    DB_HOSTNAME = "host.docker.internal";
    DB_PORT = builtins.toString config.services.postgresql.port;
    DB_USERNAME = "immich";
    DB_DATABASE_NAME = "immich";

    # redis
    REDIS_HOSTNAME = "immich-redis";

    # typesense
    TYPESENSE_HOST =  "immich-typesense";
    TYPESENSE_API_KEY = "1234567890";
    TYPESENSE_DATA_DIR = "/data";

  };

  # Networking for docker containers
  extraOptions = [
    "--add-host=host.docker.internal:host-gateway"
    "--network=immich"
  ];

  # Secrets available to docker containers
  environmentFiles = [ config.age.secrets.immich-env.path ];

  serviceConfig = {

    # Containers will not stop gracefully, so kill it
    KillSignal = "SIGKILL";
    SuccessExitStatus = "0 SIGKILL";

    # Secrets available to systemd service
    EnvironmentFile = config.age.secrets.immich-env.path;

  };

}
