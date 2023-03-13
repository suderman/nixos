# services.btrbk.enable = true;
{ config, lib, pkgs, user, ... }: 

with pkgs; 

let 
  cfg = config.services.btrbk;

in {

  options = {
    services.btrbk.enable = lib.options.mkEnableOption "btrbk"; 
  };

  # Use btrbk to snapshot persistent states and home
  config = lib.mkIf cfg.enable {

    # timestamp_format        long
    # snapshot_preserve_min   18h
    # snapshot_preserve       48h
    #
    # snapshot_dir /nix/snaps
    # subvolume    /nix/state
    # subvolume    /nix/state/home

    services.btrbk.extraPackages = [ pkgs.lz4 ];

    # Snapshot on the start and the middle of every hour.
    services.btrbk.instances.local = {
      onCalendar = "*:00,30";
      settings = {
        timestamp_format = "long";
        preserve_day_of_week = "monday";
        preserve_hour_of_day = "23";
        # All snapshots are retained for at least 6 hours regardless of other policies.
        snapshot_preserve_min = "6h";
        volume."/nix" = {
          snapshot_dir = "snaps";
          subvolume."state".snapshot_preserve = "48h 7d";
          subvolume."state/home".snapshot_preserve = "48h 7d 4w";
        };
      };
    };

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
