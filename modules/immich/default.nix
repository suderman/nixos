# modules.immich.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/immich-app/immich/releases
  version = "1.97.0";

  cfg = config.modules.immich;

  inherit (lib) mkIf mkOption mkAfter mkBefore options types strings;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;
  inherit (this.lib) extraGroups ls;

in {

  # Service order reference:
  # https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
  imports = ls ./.;

  options.modules.immich = {

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

    environment = mkOption { 
      description = "Shared environment across Immich services";
      type = types.anything; 
      default = {
        PUID = toString config.ids.uids.immich;
        PGID = toString config.ids.gids.immich;
        DB_URL = "socket://immich:@/run/postgresql?db=immich";
        REDIS_SOCKET = "/run/redis-immich/redis.sock";
        REVERSE_GEOCODING_DUMP_DIRECTORY = "/usr/src/app/geocoding";
      };
    };

  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.immich = 911;
    ids.gids.immich = 911;

    users = {
      users = {

        # Create immich user
        immich = {
          isSystemUser = true;
          group = "photos";
          description = "Immich daemon user";
          home = cfg.dataDir;
          uid = config.ids.uids.immich;
        };

      # Add admins to the immich group
      } // extraGroups this.admins [ "immich" ];

      # Create immich group
      groups.immich = {
        gid = config.ids.gids.immich;
      };

    };

    # Ensure data directory exists with expected ownership
    file = let dir = {
      type = "dir"; mode = 775; 
      user = config.ids.uids.immich; 
      group = config.ids.gids.immich;
    }; in {
      "${cfg.dataDir}" = dir;
      "${cfg.dataDir}/geocoding" = dir;
    };

    # Enable database
    modules.postgresql.enable = true;
    services.redis.servers.immich = {
      enable = true;
      user = "immich";
    };

    # Postgres database configuration
    services.postgresql = {

      enable = true;
      ensureUsers = [{
        name = "immich";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "immich" ];

      # Allow connections from any docker IP addresses
      authentication = mkBefore "host immich immich 172.16.0.0/12 md5";

      # Postgres extension pgvecto.rs required since Immich 1.91.0
      extraPlugins = [
        (pkgs.pgvecto-rs.override rec {
          postgresql = config.services.postgresql.package;
          stdenv = postgresql.stdenv;
        })
      ];
      settings.shared_preload_libraries = "vectors.so";

    };

    # Immich expects its postgres user to be a "superuser"
    # ...not ideal, but getting tired of fighting against this...
    systemd.services.postgresql.postStart = mkAfter ''
      $PSQL -tAc 'ALTER USER immich WITH SUPERUSER;'
    '';

    # # Create extensions in database
    # systemd.services.postgresql.postStart = mkAfter ''
    #   $PSQL -d immich -tAc 'CREATE EXTENSION IF NOT EXISTS cube;'
    #   $PSQL -d immich -tAc 'CREATE EXTENSION IF NOT EXISTS earthdistance;'
    #   $PSQL -d immich -tAc 'CREATE EXTENSION IF NOT EXISTS vectors;'
    # '';

    # Init service
    systemd.services.immich = let service = config.systemd.services.immich; in {
      enable = true;
      description = "Set up network & database";
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ]; # run this after db
      before = [ # run this before the rest:
        "docker-immich-machine-learning.service"
        "docker-immich-server.service"
        "docker-immich-microservices.service"
      ];
      wants = service.after ++ service.before; 
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      path = with pkgs; [ docker postgresql sudo ];
      script = with config.virtualisation.oci-containers.containers; ''
        docker pull ${immich-machine-learning.image};
        docker pull ${immich-server.image};
        docker network create immich 2>/dev/null || true
      '';
    };


  }; }
