# services.immich.enable = true;
# I wrote this custom module long before the official nixos module was
# published and plan to migrate soon now that 2.0 stable release is out.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  # https://github.com/immich-app/immich/releases
  version = "2.4.1";

  cfg = config.services.immich;

  inherit (lib) mkIf mkOption mkAfter mkBefore options types;
  inherit (config.services.traefik.lib) mkAlias mkLabels;

  # Shared environment across Immich services
  environment = {
    PUID = toString config.ids.uids.immich;
    PGID = toString config.ids.gids.immich;
    DB_URL = "socket://immich@/run/postgresql?db=immich";
    REDIS_SOCKET = "/run/redis-immich/redis.sock";
    REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";
  };
  port = 3333; # machine learning port
in {
  # Service order reference:
  # https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
  disabledModules = ["services/web-apps/immich.nix"];

  options.services.immich = {
    enable = options.mkEnableOption "immich";

    version = mkOption {
      type = types.str;
      default = version;
    };

    name = mkOption {
      type = types.str;
      default = "immich";
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
      type = types.str;
      default = ""; # Photos directory for the Immich instance
    };

    externalDir = mkOption {
      type = types.str;
      default = ""; # External library directory for the Immich instance
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

      # Allow connections from any docker IP addresses
      authentication = mkBefore "host immich immich 172.16.0.0/12 md5";

      # Postgres extension pgvecto.rs required since Immich 1.91.0
      extensions = [
        (pkgs.postgresqlPackages.pgvecto-rs.override rec {
          postgresql = config.services.postgresql.package;
        })
      ];
      settings.shared_preload_libraries = "vectors.so";
    };

    # Immich expects its postgres user to be a "superuser"
    # ...not ideal, but getting tired of fighting against this...
    systemd.services.postgresql.postStart = mkAfter ''
      ${config.services.postgresql.package}/bin/psql -tAc 'ALTER USER immich WITH SUPERUSER;'
    '';

    # Init service
    systemd.services.immich = let
      service = config.systemd.services.immich;
    in {
      enable = true;
      description = "Set up network & database";
      wantedBy = ["multi-user.target"];
      after = ["postgresql.service"]; # run this after db
      before = [
        # run this before the rest:
        "docker-immich-machine-learning.service"
        "docker-immich-server.service"
      ];
      wants = service.after ++ service.before;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      path = with pkgs; [docker postgresql sudo];
      script = with config.virtualisation.oci-containers.containers; ''
        docker pull ${immich-machine-learning.image};
        docker pull ${immich-server.image};
        docker network create immich 2>/dev/null || true
      '';
    };

    # Server back-end
    virtualisation.oci-containers.containers.immich-server = {
      image = "ghcr.io/immich-app/immich-server:v${cfg.version}";
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
        ++ (
          if cfg.photosDir == ""
          then []
          else [
            "${cfg.photosDir}:/usr/src/app/upload/library"
          ]
        )
        ++ (
          if cfg.externalDir == ""
          then []
          else [
            "${cfg.externalDir}:/external:ro"
          ]
        );

      # Traefik labels
      extraOptions =
        mkLabels cfg.name
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

    # Extend systemd service
    systemd.services.docker-immich-server = {
      requires = ["immich.service"];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };
    };

    # Machine learning
    virtualisation.oci-containers.containers.immich-machine-learning = let
      version =
        if cfg.cuda
        then "${cfg.version}-cuda"
        else cfg.version;
    in {
      image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
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
          "--network=immich"
        ]
        ++ (
          if cfg.cuda
          then ["--device=nvidia.com/gpu=all"]
          else []
        ); # use nvidia gpu if present
    };

    # Extend systemd service
    systemd.services.docker-immich-machine-learning = {
      requires = ["immich.service"];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };
    };

    # Open firewall
    networking.firewall = {
      allowedTCPPorts = [port];
    };
  };
}
