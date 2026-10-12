# services.immich.enable = true;
# I wrote this custom module long before the official nixos module was
# published. Migrate once nixpkgs packages a version at or above the pinned
# containers, since Immich cannot downgrade its database.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.services.immich;
  pin = flake.inputs.pins.default.containers.immich;

  inherit (lib) concatMapStrings mkEnableOption mkIf mkOption optional types;
  inherit (config.services.traefik.lib) mkAlias mkLabels;

  # Shared environment across Immich services
  environment = {
    PUID = toString config.ids.uids.immich;
    PGID = toString config.ids.gids.immich;
    DB_URL = "postgresql://immich@/immich?host=/run/postgresql";
    IMMICH_MEDIA_LOCATION = "/usr/src/app/upload";
    REDIS_SOCKET = "/run/redis-immich/redis.sock";
    REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";
  };
  port = 3333; # machine learning port

  # Containers are started by immich.service, which runs first
  containerService = {
    requires = ["immich.service"];

    # Container will not stop gracefully, so kill it
    serviceConfig = {
      KillSignal = "SIGKILL";
      SuccessExitStatus = "0 SIGKILL";
    };
  };
in {
  # Service order reference:
  # https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
  disabledModules = ["services/web-apps/immich.nix"];

  options.services.immich = {
    enable = mkEnableOption "immich";

    name = mkOption {
      type = types.str;
      default = "immich-server";
    };

    alias = mkOption {
      type = types.anything;
      default = null;
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/immich"; # Data directory for the Immich instance
    };

    photosDir = mkOption {
      type = with types; nullOr str;
      default = null; # Photos directory for the Immich instance
    };

    externalDir = mkOption {
      type = with types; nullOr str;
      default = null; # External library directory for the Immich instance
    };

    cuda = mkOption {
      type = types.bool;
      default = false; # Enable with nvidia gpu
    };
  };

  config = mkIf cfg.enable {
    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.immich = 911;
    ids.gids.immich = 911;

    users = {
      users =
        {
          # Create immich user
          immich = {
            isSystemUser = true;
            group = "photos";
            description = "Immich daemon user";
            home = cfg.dataDir;
            uid = config.ids.uids.immich;
          };

          # Add sudoers to the immich group
        }
        // flake.lib.extraGroups (flake.lib.sudoers flake.users) ["immich"];

      # Create immich group
      groups.immich = {
        gid = config.ids.gids.immich;
      };
    };

    # Ensure data directory exists with expected ownership
    tmpfiles.directories = [
      {
        target = cfg.dataDir;
        mode = 775;
        user = config.ids.uids.immich;
        group = config.ids.gids.immich;
      }
      {
        target = "${cfg.dataDir}/geocoding";
        mode = 775;
        user = config.ids.uids.immich;
        group = config.ids.gids.immich;
      }
    ];

    # Persist photos
    persist.storage.directories = [cfg.dataDir];

    # Enable redis
    services.redis.servers.immich = {
      enable = true;
      user = "immich";
    };

    # Postgres database configuration
    services.postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "immich";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["immich"];

      # Immich now uses VectorChord, which depends on pgvector.
      extensions = ps: [
        ps.pgvector
        ps.vectorchord
      ];
      settings.shared_preload_libraries = "vchord.so";
    };

    # Run after postgresql-setup has created the immich role and database.
    # Errors are logged without failing postgresql.target for other services.
    systemd.services.postgresql-setup.serviceConfig.ExecStartPost = let
      extensions = ["unaccent" "uuid-ossp" "cube" "earthdistance" "pg_trgm" "vector" "vchord"];
      sql =
        pkgs.writeText "immich-setup.sql"
        # sql
        ''
          -- Immich expects its postgres user to be a "superuser"
          -- ...not ideal, but getting tired of fighting against this...
          ALTER USER immich WITH SUPERUSER;

          SELECT COALESCE(installed_version, ''') AS vchord_before FROM pg_available_extensions WHERE name = 'vchord' \gset
          ${concatMapStrings (ext: "CREATE EXTENSION IF NOT EXISTS \"${ext}\" CASCADE;\n") extensions}
          ${concatMapStrings (ext: "ALTER EXTENSION \"${ext}\" UPDATE;\n") extensions}
          SELECT COALESCE(installed_version, ''') AS vchord_after FROM pg_available_extensions WHERE name = 'vchord' \gset

          -- https://docs.immich.app/administration/postgres-standalone/#updating-vectorchord
          SELECT (:'vchord_before' != ''' AND :'vchord_before' != :'vchord_after') AS vchord_updated \gset
          \if :vchord_updated
            REINDEX INDEX face_index;
            REINDEX INDEX clip_index;
          \endif
        '';
    in ["${lib.getExe' config.services.postgresql.finalPackage "psql"} -d immich -f ${sql}"];

    systemd.services = {
      # Init service
      immich = let
        containers = ["docker-immich-machine-learning.service" "docker-immich-server.service"];
      in {
        description = "Set up Immich network";
        wantedBy = ["multi-user.target"];
        after = ["docker.service" "postgresql.target"]; # run this after db
        before = containers; # run this before the rest
        wants = ["postgresql.target"] ++ containers;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
        };
        path = [pkgs.docker];
        script =
          # bash
          ''
            docker network inspect immich >/dev/null 2>&1 || docker network create immich
          '';
      };

      docker-immich-server = containerService;
      docker-immich-machine-learning = containerService;
    };

    # Server back-end
    virtualisation.oci-containers.containers.immich-server = {
      image = pin.serverImage;
      autoStart = false;

      # Run as immich user
      user = "${environment.PUID}:${environment.PGID}";

      # Environment variables
      inherit environment;

      # Map volumes to host
      volumes =
        [
          "/run/postgresql:/run/postgresql"
          "/run/redis-immich:/run/redis-immich"
          "${cfg.dataDir}/geocoding:/usr/src/app/geocoding"
          "${cfg.dataDir}:/usr/src/app/upload"
        ]
        ++ optional (cfg.photosDir != null) "${cfg.photosDir}:/usr/src/app/upload/library"
        ++ optional (cfg.externalDir != null) "${cfg.externalDir}:/external:ro";

      # Traefik labels
      extraOptions =
        mkLabels [cfg.name 2283]
        # Networking for docker containers
        ++ [
          "--network=immich"
          # https://github.com/immich-app/immich/blob/main/docker/hwaccel.yml
          "--device=/dev/dri:/dev/dri"
        ];
    };

    # Enable reverse proxy
    services.traefik = {
      enable = true;
      proxy = mkAlias cfg.name cfg.alias;
    };

    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = {
      image =
        if cfg.cuda
        then pin.machineLearningCudaImage
        else pin.machineLearningImage;
      autoStart = false;

      # Environment variables
      inherit environment;

      # Map volumes to host
      volumes = [
        "immich-machine-learning:/cache"
      ];

      # Make ML available on network
      ports = ["${toString port}:3003"];

      # Networking for docker containers
      extraOptions =
        [
          ''--network=immich''
          ''--health-cmd=python3 -c "import socket; s = socket.create_connection(('127.0.0.1', 3003), 2); s.close()"''
        ]
        ++ optional cfg.cuda "--device=nvidia.com/gpu=all"; # use nvidia gpu if present
    };

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [port];
    };
  };
}
