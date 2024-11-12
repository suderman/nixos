{ config, pkgs, ... }: let 

  automount = [ 
    "noauto"                       # do not mount on boot
    "nofail"                       # continue boot even if disk is missing
    "x-systemd.automount"          # create automount unit to mount when accessed
    "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
    "x-systemd.idle-timout=5m"     # unmount after 5 min of inactivity
  ];
  nfs = [ 
    "noauto"                       # do not mount on boot
    "nofail"                       # continue boot even if disk is missing
    "x-systemd.automount"          # create automount unit to mount when accessed
    "x-systemd.idle-timout=1m"     # unmount after 1 min of inactivity
    "_netdev"                      # mark as network device
    "fsc"                          # local cache
    "rsize=65536" "wsize=65536"    # max read/write size 64 KB
    "soft"                         # allow client to give up operations
    "x-systemd.mount-timeout=10"   # give up attempting to mount after 10 seconds
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

  # Media network share
  # -------------------------------------------------------------------------
  fileSystems."/media" = {
    device = "lux:/media"; 
    fsType = "nfs";
    options = nfs;
  };

  # allow fsc option
  services.cachefilesd.enable = true;

  # # USB drive backup (work)
  # # -------------------------------------------------------------------------
  # # Assuming the disk is "sda", create the partion table and new partition:
  # # > parted -s /dev/sda mklabel gpt
  # # > parted -s /dev/sda mkpart citadel btrfs 1MiB 100%
  # #
  # # Format the partition as btrfs
  # # > mkfs.btrfs -fL citadel /dev/sda1
  # #
  # # Mount the partition and create a backups subvolume
  # # > mkdir -p /mnt/citadel
  # # > mount /dev/sda1 /mnt/citadel
  # # > btrfs subvolume create /mnt/citadel/backups
  #
  # fileSystems."/mnt/citadel" = {
  #   fsType = "btrfs"; 
  #   device = "/dev/disk/by-uuid/243e60e9-7dab-44bc-bd56-2be667f4f78c";
  #   options = btrfs ++ automount;
  # };
  #
  # # USB drive backup (home)
  # # -------------------------------------------------------------------------
  # # Assuming the disk is "sdb", create the partion table and new partition:
  # # > parted -s /dev/sdb mklabel gpt
  # # > parted -s /dev/sdb mkpart safehouse btrfs 1MiB 100%
  # #
  # # Format the partition as btrfs
  # # > mkfs.btrfs -fL safehouse /dev/sdb1
  # #
  # # > mkdir -p /mnt/safehouse
  # # > mount /dev/sdb1 /mnt/safehouse
  # # > btrfs subvolume create /mnt/safehouse/backups  
  #
  # fileSystems."/mnt/safehouse" = {
  #   fsType = "btrfs"; 
  #   device = "/dev/disk/by-uuid/f76c2e2d-ad36-46f8-ad16-4ebdbc1bc8b4";
  #   options = btrfs ++ automount;
  # };


  # Snapshots & backups
  services.btrbk = with config.networking; {
    enable = true;

    # # Backup snapshots to USB drive when attached
    # snapshots = {
    #   "/nix".target."/mnt/safehouse/backups/${hostName}" = {};
    #   "/nix".target."/mnt/citadel/backups/${hostName}" = {};
    # };

    # Nightly backups over SSH
    backups = {
      "/nix".target."ssh://eve/backups/${hostName}" = {};
    };

  };

}
