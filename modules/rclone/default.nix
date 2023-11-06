# inspired by https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/networking/wg-quick.nix
{ config, lib, pkgs, utils, ... }:

let

  cfg = config.modules.rclone;

  inherit (config.users) user;
  inherit (lib) mkIf mkOption mkBefore options types strings nameValuePair mapAttrs';
  inherit (builtins) toString;
  inherit (lib.strings) toInt;
  # Type for a valid systemd unit name. Needed for correctly passing "requiredBy" to "systemd.services"
  inherit (utils.systemdUtils.lib) unitNameType;

  mountOpts = {
    options = {
      remote = mkOption {
        type = types.str;
        description = "Name of rclone remote defined in RClone config. Keep in mind to add the `:` after the name.";
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

      mountOpts = mkOption {
        type = types.listOf (types.str);
        default = [];
        description = "Additional paramenters passed as mount options";
        example = ["noauto" "_netdev"];
      };
    };
  };

  generateMount = name: values:
    let
      fsValue = {
        device = values.remote;
        fsType = "rclone";
        options = [
          "rw"
          "allow_other"
          "_netdev"
          "noauto"
          "x-systemd.automount"
          # "x-systemd.idle-timeout=60"

          # rclone specific
          "env.PATH=/run/wrappers/bin" # for fusermount3
          "config=${values.configPath}"
          "cache_dir=${values.cacheDir}"
          "uid=${toString values.uid}"
          "gid=${toString values.gid}"
          "dir-perms=770"
          "file-perms=0664"
          "umask=002"
          "allow-non-empty"
          "allow-other"
          "vfs-cache-mode=full"
          "vfs-cache-max-size=10G"
        ] ++ values.mountOpts;
      };
    in
    nameValuePair "${name}" fsValue;


in {  

  ###### interface

  options.modules.rclone = {
      mounts = mkOption {
        description = "Rcloune mounts.";
        default = {};
        example = {
          "/mnt/rclone" = {
            configPath = "/etc/rclone/rclone.conf";
            remote = "my-remote:";
            cacheDir = "/var/lib/rclone";
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