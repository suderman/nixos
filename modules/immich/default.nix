# modules.immich.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/immich-app/immich/releases
  version = "1.89.0";

  cfg = config.modules.immich;

  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;
  inherit (this.lib) extraGroups;

in {

  # Service order reference:
  # https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
  imports = [
    ./environment.nix
    ./immich-redis.nix
    ./immich-typesense.nix
    ./immich-server.nix
    ./immich-microservices.nix
    ./immich-machine-learning.nix
  ];


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

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik.enable = true;

    # Postgres database configuration
    services.postgresql = {

      enable = true;
      ensureUsers = [{
        name = "immich";
        ensurePermissions = { "DATABASE immich" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "immich" ];

      # Allow connections from any docker IP addresses
      authentication = mkBefore "host immich immich 172.16.0.0/12 md5";

    };

    # Init service
    systemd.services.immich = let this = config.systemd.services.immich; in {
      enable = true;
      description = "Set up paths & database access";
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ]; # run this after db
      before = [ # run this before the rest:
        "docker-immich-redis.service"
        "docker-immich-typesense.service"
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
      path = with pkgs; [ docker ];
      script = with config.virtualisation.oci-containers.containers; ''
        sleep 5
        #
        # Ensure docker network exists
        ${pkgs.docker}/bin/docker network create immich 2>/dev/null || true
        #
        # Ensure data directory exists with expected ownership
        mkdir -p ${cfg.dataDir}/geocoding
        chown -R ${cfg.environment.PUID}:${cfg.environment.PGID} ${cfg.dataDir}
        #
        # Ensure database user has expected password
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql postgres \
          -c "alter user immich with password '$DB_PASSWORD'"
        #
        # Pull all docker images
        docker pull ${immich-typesense.image};
        docker pull ${immich-redis.image};
        docker pull ${immich-machine-learning.image};
        docker pull ${immich-server.image};
      '';
    };

    # # todo: replace mkdir with tmpfiles
    # systemd.tmpfiles.rules = [
    #   "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    # ];

    # # sudo systemctl start immich-pull
    # systemd.services.immich-pull = {
    #   description = "Pull docker images for Immich";
    #   serviceConfig.Type = "oneshot";
    #   path = with pkgs; [ docker ];
    #   script = with config.virtualisation.oci-containers.containers; ''
    #     docker pull ${immich-typesense.image};
    #     docker pull ${immich-redis.image};
    #     docker pull ${immich-machine-learning.image};
    #     docker pull ${immich-server.image};
    #   '';
    # };

  };

}
