# modules.postgresql.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.postgresql;
  admins = this.admins ++ [ "root" ]; 
  databases = mkAttrs (unique config.services.postgresql.ensureDatabases) ( database: admins );
  inherit (lib) mkIf mkOrder mkOption options types unique;
  inherit (this.lib) mkAttrs;

in {

  options.modules.postgresql = {

    enable = options.mkEnableOption "postgresql"; 

    # 14 was default package as of 22.11
    # 15 is default package as of 23.11
    package = mkOption {
      type = types.package;
      default = pkgs.postgresql_14;
    };

  };


  config = mkIf cfg.enable {

    services.postgresql = {

      enable = true;
      package = cfg.package; 

      # Database & role for each admin
      ensureDatabases = admins;
      ensureUsers = (map (name: 
        { inherit name; ensureDBOwnership = true; }
      ) admins);

      # Listen everywhere
      enableTCPIP = true;

      # Allow password-less access on 127.0.0.1 
      authentication = mkOrder 600 ''
        host all all 127.0.0.1/32 ident
      '';

    };

    # Ensure privileges for all database users and admins
    systemd.services.postgresql.postStart = let 
      inherit (lib) concatLines flatten mapAttrsToList;
      sql = unique( flatten( 
        mapAttrsToList( database: admins: ([ 
            # Grant all priveleges for this database to the database user
            "$PSQL -d \"${database}\" -tAc 'GRANT ALL PRIVILEGES ON SCHEMA public TO \"${database}\";'"
          ] ++ ( map( admin: 
            # Grant all priveleges for this database to each admin user
            "$PSQL -d \"${database}\" -tAc 'GRANT ALL PRIVILEGES ON SCHEMA public TO \"${admin}\";'"
          ) admins ) 
        )) databases 
      ));
    in mkOrder 1400 (concatLines sql);

    # ident is equivalent to peer, but requires identd daemon
    services.oidentd.enable = true;

    # Allow docker containers to connect
    networking.firewall.allowedTCPPorts = [ config.services.postgresql.port ];

  };

}
