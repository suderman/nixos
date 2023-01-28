{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.postgresql;

in {

  # services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_15;
  services.postgresql.ensureUsers = [{
    name = user;
    ensurePermissions = {
      "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
    };
  }];

}
