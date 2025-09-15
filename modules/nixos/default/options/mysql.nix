# services.mysql.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mysql;
  admins = config.users.groups.wheel.members ++ ["root"];
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    services.mysql = {
      user = "mysql";
      group = "mysql";

      package = pkgs.mysql80;
      ensureUsers =
        map (
          name: {
            inherit name;
            ensurePermissions = {
              "*.*" = "ALL PRIVILEGES";
            };
          }
        )
        admins;
    };

    services.mysqlBackup = {
      enable = true;
      location = cfg.dataDir;
    };

    # Persist data between reboots
    persist.storage.directories = [cfg.dataDir];
  };
}
