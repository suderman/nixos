# modules.btrbk.enable = true;
{ config, lib, pkgs, user, ... }: 

let 

  cfg = config.modules.btrbk;
  secrets = config.age.secrets;
  keys = config.modules.secrets.keys;
  inherit (lib) mkIf mkOption mkForce types recursiveUpdate;

in {

  options.modules.btrbk = {
    enable = lib.options.mkEnableOption "btrbk"; 
    snapshot = mkOption { type = types.attrs; default = {}; };
    backup = mkOption { type = types.attrs; default = {}; };
  };

  # Use btrbk to snapshot persistent states and home
  config = mkIf cfg.enable {

    # timestamp_format        long
    # snapshot_preserve_min   18h
    # snapshot_preserve       48h
    #
    # snapshot_dir /nix/snapshots
    # subvolume    /nix/state
    # subvolume    /nix/state/home

    services.btrbk.extraPackages = [ pkgs.lz4 pkgs.mbuffer ];

    services.btrbk.sshAccess = [{
      key = keys.users.btrbk;
      roles = [ "info" "source" "target" "delete" "snapshot" "send" "receive" ];
    }];

    # # Snapshot on the start and the middle of every hour.
    # services.btrbk.instances.btrbk = {
    #   onCalendar = "*:00,30";
    #   settings = {
    #
    #     ssh_user = "btrbk";
    #     ssh_identity = secrets.btrbk-key.path;
    #
    #     stream_compress = "lz4";
    #     stream_buffer = "256m";
    #
    #     timestamp_format = "long";
    #     preserve_day_of_week = "monday";
    #     preserve_hour_of_day = "23";
    #
    #     # All snapshots are retained for at least 6 hours regardless of other policies.
    #     snapshot_dir = "snapshots";
    #     snapshot_preserve_min = "6h";
    #     snapshot_preserve = "48h 7d";
    #
    #     target_preserve_min = "1w";
	  #     target_preserve = "30d 12w 6m";
    #
    #     volume."/nix" = {
    #       # snapshot_dir = "snapshots";
    #       subvolume."state".snapshot_preserve = "48h 7d";
    #       subvolume."state/home".snapshot_preserve = "48h 7d 4w";
    #     };
    #   };
    # };

    services.btrbk.instances = let

      shared = {
        timestamp_format = "long";
        preserve_day_of_week = "monday";
        preserve_hour_of_day = "23";
        stream_buffer = "256m";
        snapshot_dir = "snapshots";
      };

    in {

      # Instance was "snapshot" but now named "btrbk" so it generates default btrbk.conf
      "btrbk" = {
        onCalendar = "*:00,30";
        settings = shared // {
          snapshot_create = "onchange";
          snapshot_preserve_min = "6h";
          snapshot_preserve = "48h 7d 4w";
          volume = recursiveUpdate {
            "/nix" = {
              subvolume."state" = {};
              subvolume."state/home" = {};
            };
          } cfg.snapshot; 
        };
      };
      
      # All snapshots are retained for at least 6 hours regardless of other policies.
      "backup" = {
        onCalendar = "daily 02:00";
        settings = shared // {
          ssh_user = "btrbk";
          ssh_identity = secrets.btrbk-key.path;
          stream_compress = "lz4";
          snapshot_create = "ondemand";
          snapshot_preserve_min = "latest";
          target_preserve_min = "1d";
          target_preserve = "7d 4w 6m";
          volume = recursiveUpdate {
            "/nix" = {
              subvolume."state" = {};
              subvolume."state/home" = {};
            }; 
          } cfg.backup;
        };
      };

    };

    # Allow btrbk user to read ssh key file
    # users.users.btrbk.extraGroups = [ "secrets" ]; 

    age.secrets.btrbk-key = {
      owner = mkForce "btrbk";
      mode = mkForce "400"; 
    };

    # services.btrbk.instances.local.settings = {
    #   volume."/data" = {
    #     snapshot_dir = "snapshots";
    #     subvolume."photos".snapshot_preserve = "48h 7d";
    #   };
    # };

    # services.btrbk.instances.remote = {
    #   onCalendar = "weekly";
    #   settings = {
    #     ssh_identity = "/etc/btrbk_key"; # NOTE: must be readable by user/group btrbk
    #     ssh_user = "btrbk";
    #     stream_compress = "lz4";
    #     volume."/nix" = {
    #       target = "ssh://umbra.suderman.org/mnt/mybackups";
    #       subvolume."state".snapshot_preserve = "48h 7d";
    #       subvolume."state/home".snapshot_preserve = "48h 7d";
    #     };
    #   };
    # };

  };
}
