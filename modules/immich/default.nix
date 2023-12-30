# modules.immich.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/immich-app/immich/releases
  version = "1.91.4";

  cfg = config.modules.immich;

  inherit (lib) mkIf mkOption mkBefore options types strings;
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
      description = "Version of the Immich instance";
    };

    hostName = mkOption {
      type = types.str;
      default = "immich.${config.networking.fqdn}";
      description = "FQDN for the Immich instance";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/immich";
      description = "Data directory for the Immich instance";
    };

    photosDir = mkOption {
      type = types.str;
      default = "";
      description = "Photos directory for the Immich instance";
    };

    externalDir = mkOption {
      type = types.str;
      default = "";
      description = "External library directory for the Immich instance";
    };

    environment = mkOption { 
      type = types.attrs; 
      default = {};
      description = "Shared environment across Immich services";
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

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik.enable = true;

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
      settings = { shared_preload_libraries = "vectors.so"; };

    };

    # Init service
    systemd.services.immich = let this = config.systemd.services.immich; in {
      enable = true;
      description = "Set up network & database";
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ]; # run this after db
      before = [ # run this before the rest:
        "docker-immich-redis.service"
        "docker-immich-machine-learning.service"
        "docker-immich-server.service"
        "docker-immich-microservices.service"
      ];
      wants = this.after ++ this.before; 
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        EnvironmentFile = cfg.environment.file;
      };
      path = with pkgs; [ docker postgresql sudo ];
      script = with config.virtualisation.oci-containers.containers; ''

        # Pull all docker images v${version}
        docker pull ${immich-redis.image};
        docker pull ${immich-machine-learning.image};
        docker pull ${immich-server.image};
        
        # Ensure docker network exists
        docker network create immich 2>/dev/null || true
        
        # Ensure database user has expected password, temporarily become superuser
        sudo -u postgres psql postgres -c "\
          ALTER USER immich WITH PASSWORD '$DB_PASSWORD'; \
          ALTER USER immich WITH SUPERUSER; \
        "
        # Create extensions as database user
        sudo -u immich psql immich -c "\
          CREATE EXTENSION IF NOT EXISTS cube; \
          CREATE EXTENSION IF NOT EXISTS earthdistance; \
          CREATE EXTENSION IF NOT EXISTS vectors; \
        "
        # Revoke superuser
        sudo -u postgres psql postgres -c "\
          ALTER USER immich WITH NOSUPERUSER; \
        "
        
      '';
    };

  };

}
