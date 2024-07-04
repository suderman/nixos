# services.mysql.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.services.mysql;
  inherit (lib) mkIf mkOption types;

in {

  config = mkIf cfg.enable {
    services.mysql = {

      user = "mysql";
      group = "mysql";

      package = pkgs.mysql80;

      ensureUsers = [{
        name = builtins.head this.admins;
        ensurePermissions = {
          "*.*" = "ALL PRIVILEGES";
        };
      }];

    };

    services.mysqlBackup = {
      enable = true;
      location = "/var/lib/mysql";
    };

  };

}
