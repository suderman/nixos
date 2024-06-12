# modules.photoprism.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.photoprism;

  inherit (lib) mkIf mkOption mkBefore mkForce types;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;
  inherit (config.age) secrets;

in {

  options.modules.photoprism = {
    enable = lib.options.mkEnableOption "photoprism"; 
    name = mkOption {
      type = types.str;
      default = "photoprism";
    };
    port = mkOption {
      type = types.port;
      default = 2342; 
    };
    dataDir = mkOption {
      type = types.str; 
      default = "/var/lib/photoprism"; 
    };
    photosDir = mkOption {
      type = types.str;
      default = null; 
    };
  };

  config = mkIf cfg.enable {

    ids.uids.photoprism = 910;
    ids.gids.photoprism = 910;

    users.users.photoprism = {
      isSystemUser = true;
      group = "photos";
      description = "photoprism daemon user";
      home = cfg.dataDir;
      uid = config.ids.uids.photoprism;
    };

    users.groups.photoprism = {
      gid = config.ids.gids.photoprism;
    };

    services.photoprism = {
      enable = true;
      package = pkgs.unstable.photoprism;
      passwordFile = secrets.password.path;
      port = cfg.port;
      settings.PHOTOPRISM_ADMIN_USER = builtins.head this.admins;
      originalsPath = cfg.photosDir;
      storagePath = cfg.dataDir;
    };

    # Extend systemd service
    systemd.services.photoprism = {
    
      # Allow photoprism user to read password file
      serviceConfig.DynamicUser = mkForce false; 
      # serviceConfig.SupplementaryGroups = [ "secrets" ]; 
      # serviceConfig.Group = mkForce "photos"; 
      # preStart = mkBefore "usermod -a -G secrets photoprism"; 

    };

    #   # Secret environment variables (SMTP credentials)
    #   serviceConfig.EnvironmentFile = secrets.smtp-env.path; 
    #
    #   # Database should be running before this service starts
    #   after = [ "postgresql.service" ];
    #
    #   # If the db goes down, take down this service too
    #   requires = [ "postgresql.service" ];
    #
    # };
    #
    # # Postgres database configuration
    # services.postgresql = {
    #   ensureUsers = [{
    #     name = "gitea";
    #     ensureDBOwnership = true;
    #   }];
    #   ensureDatabases = [ "gitea" ];
    # };

    # Allow photoprism user to read password file and photos
    users.users.photoprism.extraGroups = [ "secrets" ]; 

    modules.traefik = { 
      enable = true;
      routers."${cfg.name}" = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
