# services.postgresql.enable = true;
{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.postgresql;

in {

  config = lib.mkIf cfg.enable {

    # Current default
    services.postgresql.package = pkgs.postgresql_14;

    services.postgresql.ensureUsers = [{
      name = user;
      ensurePermissions = {
        "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
      };
    }];
    services.postgresql.ensureDatabases = [ user ];

  };

}
