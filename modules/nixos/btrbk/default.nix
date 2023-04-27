# modules.btrbk.enable = true;
{ config, lib, pkgs, ... }: 

let 

  cfg = config.modules.btrbk;
  secrets = config.age.secrets;
  inherit (lib) mkIf mkOption mkForce types recursiveUpdate;

in {

  options.modules.btrbk = {
    enable = lib.options.mkEnableOption "btrbk"; 
    snapshots = mkOption { type = types.attrs; default = {}; };
    backups = mkOption { type = types.attrs; default = {}; };
  };

  # Use btrbk to snapshot persistent states and home
  config = mkIf cfg.enable {

    # Public key to private key found in secrets/files/btrbk-key.age
    # > ssh-keygen -t ed25519 -C btrbk -f /tmp/btrbk
    services.btrbk.sshAccess = [{
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTAr4tawFxq0q+cazxkwfIqFPF3CdkY1kCGZNVn9LWj";
      roles = [ "info" "source" "target" "delete" "snapshot" "send" "receive" ];
    }];

    # Enable compression
    services.btrbk.extraPackages = [ pkgs.lz4 pkgs.mbuffer ];

    services.btrbk.instances = let

      shared = {
        timestamp_format = "long";
        preserve_day_of_week = "monday";
        preserve_hour_of_day = "23";
        stream_buffer = "256m";
        snapshot_dir = "snapshots";
        ssh_user = "btrbk";
        ssh_identity = secrets.btrbk-key.path;
      };

    in {

      # All snapshots are retained for at least 6 hours regardless of other policies.
      "snapshots" = {
        onCalendar = "*:00";
        settings = shared // {
          snapshot_create = "onchange";
          snapshot_preserve_min = "6h";
          snapshot_preserve = "48h 7d 4w";
          volume = recursiveUpdate {
            "/nix" = {
              subvolume."state" = {};
              subvolume."state/home" = {};
            };
          } cfg.snapshots; 
        };
      };
      
      # Send snapshots to backup targets (none declared here) at 12:15 every night.
      "backups" = {
        onCalendar = "00:15";
        settings = shared // {
          stream_compress = "lz4";
          snapshot_create = "no";
          snapshot_preserve_min = "all";
          target_preserve_min = "1d";
          target_preserve = "7d 4w 6m";
          volume = recursiveUpdate {
            "/nix" = {
              subvolume."state" = {};
              subvolume."state/home" = {};
            }; 
          } cfg.backups;
        };
      };

    };

    # Point default btrbk.conf to backup config
    environment.etc."btrbk.conf".source = "/etc/btrbk/backups.conf";

    # Allow btrbk user to read ssh key file
    age.secrets.btrbk-key = {
      owner = mkForce "btrbk";
      mode = mkForce "400"; 
    };

  };
}
