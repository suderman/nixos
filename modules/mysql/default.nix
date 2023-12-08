# modules.mysql.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.mysql;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.mysql = {
    enable = lib.options.mkEnableOption "mysql"; 
  };

  config = mkIf cfg.enable {

    services.mysql = {

      enable = true;

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
