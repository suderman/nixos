# services.mysql.enable = true;
{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.mysql;

in {

  config = lib.mkIf cfg.enable {

    services.mysql.user = "mysql";
    services.mysql.group = "mysql";

    services.mysql.package = pkgs.mysql80;
    services.mysql.ensureUsers = [{
      name = user;
      ensurePermissions = {
        "*.*" = "ALL PRIVILEGES";
      };
    }];

    services.mysqlBackup = {
      enable = true;
      location = "/var/lib/mysql";
    };

  };

}
