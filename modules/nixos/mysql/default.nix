# services.mysql.enable = true;
{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.mysql;

in {

  config = lib.mkIf cfg.enable {

    services.mysql.package = pkgs.mysql80;
    services.mysql.ensureUsers = [{
      name = user;
      ensurePermissions = {
        "*.*" = "ALL PRIVILEGES";
      };
    }];

  };

}