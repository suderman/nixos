# modules.postgresql.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.postgresql;
  users = this.admins ++ [ "root" ]; 
  inherit (lib) mkIf mkOrder options;

in {

  options.modules.postgresql.enable = options.mkEnableOption "postgresql"; 

  config = mkIf cfg.enable {

    services.postgresql = {

      enable = true;

      # Default package as of 22.11
      package = pkgs.postgresql_14; 

      # Full access for personal and root user
      ensureDatabases = users;
      ensureUsers = (map (name: 
        { inherit name; ensurePermissions = { "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES"; }; }
      ) users);

      # Listen everywhere
      enableTCPIP = true;

      # Allow password-less access on 127.0.0.1 
      authentication = mkOrder 600 ''
        host all all 127.0.0.1/32 ident
      '';

    };

    # ident is equivalent to peer, but requires identd daemon
    services.oidentd.enable = true;

    # Allow docker containers to connect
    networking.firewall.allowedTCPPorts = [ config.services.postgresql.port ];

  };

}
