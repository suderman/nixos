# modules.rclone.enable = true;
{ config, lib, systemdUtils, pkgs, ... }:

let

  cfg = config.modules.rclone;

  inherit (config.users) user;
  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString;
  inherit (lib.strings) toInt;
  inherit (systemdUtils.lib) unitNameType;

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
      description = "Name of rclone remote defined in RClone config. Keep in mind to add the `:` after the name.";
    };

    mountPath = mkOption {
      type = types.path;
      default = "/mnt/rclone";
      description = "Mointpoint for rclone remote";
    };

    cacheDir = mkOption {
      type = types.path;
      default = "/var/rclone";
      description = "Cache directory for rclone vfs";
    };

    configPath = mkOption { 
      type = types.path; 
      description = "RClone config file.";
    };

    requiredBy = mkOption { 
      type = types.listOf unitNameType; 
      default = [];
      description = "Services that requrie the mount to be ready";
    };

  };

  # TODO: allow configuration of multiple mounts via <name> like here https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/networking/wg-quick.nix#L219
  # Use this to properly escape the unit name https://github.com/NixOS/nixpkgs/blob/edbe9ad5e0a129424abdde36a0124333213fc667/nixos/lib/utils.nix#L46
  config = mkIf cfg.enable {  

    # Name sanitazion: builtins.concatStringsSep "-" (builtins.filter (v: ! builtins.isList v) (builtins.split "[^[:alnum:]]" "azure:blob/dir"))
    # Add user to the rclone group
    # users.users."${user}".extraGroups = [ "rclone" ]; 

    environment.systemPackages = [ pkgs.unstable.rclone ];
    system.fsPackages = [ pkgs.unstable.rclone ];
    systemd.packages = [ pkgs.unstable.rclone ];
    
    systemd.services.rclone-azure-mount = {
      path = with pkgs; [
        "/run/wrappers" # if you need something from /run/wrappers/bin, sudo, for example
      ];
      description = "Mount rclone ";    
      wantedBy = ["multi-user.target"];
      requiredBy = cfg.requiredBy;
      # before = [ "phpfpm-nextcloud.service" ];
      serviceConfig = {
        # User = "nextcloud";
        # Group = "nextcloud";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${cfg.mountPath}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount ${cfg.remote} ${cfg.mountPath} \
            --config=${cfg.configPath} \
            --allow-other \
            --dir-perms=770 \
            --file-perms=0664 \
            --umask=002 \
            --allow-non-empty \
            --log-level=INFO \
            --vfs-cache-mode full \
            --vfs-cache-max-size 20G
        '';
        ExecStop = "/run/wrappers/bin/fusermount -u ${cfg.mountPath}";
        Type = "notify";
        Restart = "always";
        RestartSec = "10s";
      };
    };

    # systemd.mounts = [{
    #   description = "Rclone mount test";
    #   after = [ "network-online.target" ];
    #   what = cfg.remote;
    #   where = cfg.mountPath;
    #   type = "rclone";
    #   options = "rw,_netdev,allow_other,args2env,vfs-cache-mode=writes,log-level=DEBUG,config=${cfg.configPath},cache-dir=${cfg.cacheDir}"; 
    # }]; 

    # systemd.automounts = [{
    #   after = [ "network-online.target" ];
    #   before = [ "remote-fs.target" ];
    #   where = cfg.mountPath;
    #   wantedBy = [ "multi-user.target" ];
    # }];






  };

  
}