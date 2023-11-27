{ config, ... }: let 

  automount = [ 
    "noauto"                       # do not mount on boot
    "nofail"                       # continue boot even if disk is missing
    "x-systemd.automount"          # create automount unit to mount when accessed
    "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
    "x-systemd.idle-timout=5m"     # unmount after 5 min of inactivity
  ];
  btrfs = [ 
    "compress=zstd"                # enable zstd compression
    "space_cache=v2"               # track available free space on filesystem
    "discard=async"                # free up deleted space in the background
    "noatime"                      # disables access time updates on files
  ]; 
  bind = [ "bind" ]; 

in {

  # Btrfs mount options
  fileSystems."/".options = btrfs;
  fileSystems."/nix".options = btrfs;

  # # Snapshots & backups
  # modules.btrbk = {
  #   enable = true;
  #   backups = with config.networking; {
  #     "/nix".target."ssh://eve.${domain}/backups/${hostName}" = {};
  #   };
  # };


}
