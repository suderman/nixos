# services.postgresql.enable = true;
{ config, lib, pkgs, user, ... }:

let

  cfg = config.services.postgresql;
  users = [ user "root" ]; 
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.postgresql = {

      # default package as of 22.11
      package = pkgs.postgresql_14; 

      # full access for personal and root user
      ensureDatabases = users;
      ensureUsers = (map (name: 
        { inherit name; ensurePermissions = { "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES"; }; }
      ) users);

    };

  };

}
