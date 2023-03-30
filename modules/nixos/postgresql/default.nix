# services.postgresql.enable = true;
{ config, lib, pkgs, user, ... }:

let

  cfg = config.services.postgresql;
  users = [ user "root" ]; 
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.postgresql = {

      # Default package as of 22.11
      package = pkgs.postgresql_14; 

      # Full access for personal and root user
      ensureDatabases = users;
      ensureUsers = (map (name: 
        { inherit name; ensurePermissions = { "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES"; }; }
      ) users);

      # Allow password-less access on 127.0.0.1 
      authentication = lib.mkForce ''
        # Generated file; do not edit!
        local all all              peer
        host  all all 127.0.0.1/32 ident
        host  all all ::1/128      md5
      '';

    };

    # ident is equivalent to peer, but requires identd daemon
    services.oidentd.enable = true;

  };

}
