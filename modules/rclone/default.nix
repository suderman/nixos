# modules.rclone.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.rclone;

  inherit (config.users) user;
  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;

  configFile = pkgs.writeTextFile {
    name = "rclone.conf";
    text = lib.generators.toINI {} cfg.settings;
    checkPhase = "${pkgs.rclone}/bin/rclone config show --config $out";
  };

in {  
  options.modules.rclone = {

    enable = options.mkEnableOption "rclone"; 

    remote = mkOption {
      type = types.str;
      default = "memoryRemote";
      description = "Name of rclone remote defined in RClone config";
    };

    mountPath = mkOption {
      type = types.path;
      default = "/mnt/rclone/memory";
      description = "Mointpoint for rclone remote";
    };

    cacheDir = mkOption {
      type = types.path;
      default = "/var/rclone";
      description = "Cache directory for rclone vfs";
    };

    settings = mkOption { 
      type = types.attrs; 
      default = {
        memoryRemote = {
          type = "memory";
        };
      };
      description = "RClone config.";
    };

  };

  config = mkIf cfg.enable {  

    # Name sanitazion: builtins.concatStringsSep "-" (builtins.filter (v: ! builtins.isList v) (builtins.split "[^[:alnum:]]" "azure:blob/dir"))
    # Add user to the rclone group
    users.users."${user}".extraGroups = [ "rclone" ]; 

    environment.systemPackages = [ pkgs.unstable.rclone ];
    system.fsPackages = [ pkgs.unstable.rclone ];
    systemd.packages = [ pkgs.unstable.rclone ];
    
    systemd.mounts = [{
      description = "Rclone mount test";
      what = cfg.remote;
      where = cfg.mountPath;
      type = "rclone";
      options = "rw,_netdev,allow_other,args2env,vfs-cache-mode=writes,config=${configFile},cache-dir=${cfg.cacheDir}"; 
    }]; 
    # systemd.mounts = [{
    #   description = "Rclone mount for ${cfg.remote}";
    #   what = "rclone-${cfg.remote}";
    #   where = "/mnt/rclone/${cfg.remote}";
    #   type = "rclone";
    #   mountConfig = { 
    #     UnknownOption = "foo";
    #     LogLevelMax = 0;
    #   };  
    # }]; 


  };

  # systemd.services.nextcloud-blob-mount = {
  #   path = with pkgs; [
  #     "/run/wrappers" # if you need something from /run/wrappers/bin, sudo, for example
  #   ];
  #   description = "Mount nextcloud azure blob container ";    
  #   wantedBy = ["multi-user.target"];
  #   before = [ "phpfpm-nextcloud.service" ];
  #   serviceConfig = {
  #     User = "nextcloud";
  #     Group = "nextcloud";
  #     ExecStartPre = "/run/current-system/sw/bin/mkdir -p /var/lib/nextcloud/data";
  #     ExecStart = ''
  #       ${pkgs.rclone}/bin/rclone mount 'azure-data:nextcloud/' /var/lib/nextcloud/data \
  #         --config=${config.age.secrets.rclone-conf.path} \
  #         --allow-other \
  #         --dir-perms=770 \
  #         --file-perms=0664 \
  #         --umask=002 \
  #         --allow-non-empty \
  #         --log-level=INFO \
  #         --vfs-cache-mode full \
  #         --vfs-cache-max-size 20G
  #     '';
  #     ExecStop = "/run/wrappers/bin/fusermount -u /var/lib/nextcloud/data";
  #     Type = "notify";
  #     Restart = "always";
  #     RestartSec = "10s";
  #   };
  # };
}