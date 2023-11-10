# modules.blobfuse.mounts.<mountpath> = {};
# blobfuse in fstabe: https://learn.microsoft.com/en-us/answers/questions/1351939/how-can-i-get-permanent-blob-container-mount-with
{ config, lib, pkgs, utils, ... }:

let

  cfg = config.modules.blobfuse;

  inherit (config.users) user;
  inherit (lib) mkIf mkOption mkBefore options types strings nameValuePair mapAttrs';
  inherit (builtins) toString;
  inherit (lib.strings) toInt;
  # Type for a valid systemd unit name. Needed for correctly passing "requiredBy" to "systemd.services"
  inherit (utils.systemdUtils.lib) unitNameType;

  mountOpts = {
    options = {     

      configPath = mkOption { 
        type = types.path; 
        description = "blobfuse config file.";
      };

      container = mkOption {
        type = types.str;
        description = "Name of the cointainer to mount.";
      };

      mountOpts = mkOption {
        type = types.listOf (types.str);
        default = [];
        description = "Additional paramenters passed as mount options";
        example = ["noauto" "_netdev" "x-systemd.idle-timeout=60"];
      };

      uid = mkOption { 
        type = types.ints.u32; 
        default = 1000;
        description = "Override the UID field set by the filesystem.";
      };

      gid = mkOption { 
        type = types.ints.u32; 
        default = 1000;
        description = "Override the GID field set by the filesystem.";
      };

      
    };
  };

  defaultOpts = [];

  generateMount = name: values:
    let
      fsValue = {
        device = "${cfg.package}/bin/azure-storage-fuse";
        fsType = "fuse3";
        options = [
          "defaults"
          "_netdev"
          "allow_other"
          "x-systemd.automount"
          "x-systemd.mount-timeout=10s"
          "uid=${toString values.uid}"
          "gid=${toString values.gid}"

          # blobfuse args 
          "--config-file=${values.configPath}"
          "--container-name=${values.container}"
          # "--allow-other"
          # "--tmp-path=/tmp/"
        ] ++ values.mountOpts;
      };
    in
    nameValuePair "${name}" fsValue;


in {  

  ###### interface

  options.modules.blobfuse = {
      package = mkOption {
        type = types.package;
        default = pkgs.blobfuse;
        description = "blobfuse package to use.";        
      };

      mounts = mkOption {
        description = "blobfuse mounts.";
        default = {};
        example = {
          "/mnt/blobfuse" = {
            configPath = "/etc/blobfuse.yaml";

          };
        };
        type = with types; attrsOf (submodule mountOpts);
      };
  };

  ###### implementation

  config = mkIf (cfg.mounts != {}) {
    environment.systemPackages = [ pkgs.unstable.rclone ];
    system.fsPackages = [ pkgs.unstable.rclone ];
    systemd.packages = [ pkgs.unstable.rclone ];

    fileSystems = mapAttrs' generateMount cfg.mounts;
  };
}