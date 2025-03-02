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

  # Additional HDD disk pool
  # -------------------------------------------------------------------------
  # Become root, insert disk and lookup the device name:
  # > sudo -s
  # > lsblk -f
  #
  # Assuming the disks are "sda-sdb", create the parition tables and new partitions:
  # parted -s /dev/sda mklabel gpt
  # parted -s /dev/sda mkpart one btrfs 1MiB 100%
  # parted -s /dev/sdb mklabel gpt
  # parted -s /dev/sdb mkpart two btrfs 1MiB 100%
  #
  # Format as btrfs and create the pool
  # mkfs.btrfs -fL pool -d single /dev/sda1 /dev/sdb1
  #
  # Take note of the UUID and mount the pool
  # mkdir -p /mnt/pool
  # mount -t btrfs -o defaults /dev/disk/by-uuid/06ee79b6-e3bc-4e50-a586-784d732f470b /mnt/pool
  #
  # Create two subvolumes:
  # > btrfs subvolume create /mnt/pool/data
  # > btrfs subvolume create /mnt/pool/backups

  fileSystems."/mnt/pool" = {
    fsType = "btrfs"; 
    device = "/dev/disk/by-uuid/06ee79b6-e3bc-4e50-a586-784d732f470b";
    options = btrfs ++ automount;  
  };
  # services.beesd.filesystems.pool = mkBees "/mnt/pool";

  fileSystems."/data" = {
    device = "/mnt/pool/data"; 
    options = bind ++ automount;
  };

  fileSystems."/backups" = {
    device = "/mnt/pool/backups"; 
    options = bind ++ automount;
  };

  # Snapshots & backup with btrbk
  # This also allows other computers to send their backups here
  services.btrbk.enable = true;

  # Additional filesystems in motd
  programs.rust-motd.settings.filesystems = {
    pool = "/mnt/pool";
  };

}
