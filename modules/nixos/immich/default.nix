# services.immich.enable = true;
{ config, lib, pkgs, ... }:

let

  # Inspiration from:
  # https://github.com/kradalby/dotfiles/blob/9caed5967db7afd67c79fe0d8649a2ff98b0a26b/machines/core.terra/immich.nix
  cfg = config.services.immich;

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;

in {

  # Service order reference:
  # https://github.com/immich-app/immich/blob/main/docker/docker-compose.yml
  imports = [
    ./immich-web.nix
    ./immich-redis.nix
    ./immich-typesense.nix
    ./immich-server.nix
    ./immich-microservices.nix
    ./immich-machine-learning.nix
    ./immich-proxy.nix
  ];


  options = {

    services.immich.enable = mkEnableOption "immich"; 

    services.immich.host = mkOption {
      type = types.str;
      default = "immich.${config.networking.fqdn}";
      description = "Host for Immich";
    };

    services.immich.dataDir = mkOption {
      type = types.path;
      default = "/var/lib/immich";
      description = "Data directory for Immich";
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


    # Postgres database configuration
    services.postgresql = {

      enable = true;
      ensureUsers = [{
        name = "immich";
        ensurePermissions = { "DATABASE immich" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "immich" ];

      # Allow connections from any docker IP addresses
      authentication = mkBefore ''
        host immich immich 172.17.0.0/12 md5
      '';

    };


  };

}
