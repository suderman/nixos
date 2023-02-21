# services.postgresql.enable = true;
{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.postgresql;

in {

  config = lib.mkIf cfg.enable {

    services.postgresql.package = pkgs.postgresql_15;
    services.postgresql.ensureUsers = [{
      name = user;
      ensurePermissions = {
        "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
      };
    }];

  };

}
