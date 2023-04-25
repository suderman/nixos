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

  # Additional SSD disk
  # -------------------------------------------------------------------------
  # Become root, insert disk and lookup the device name:
  # > sudo -s
  # > lsblk -f
  #
  # Assuming the disk is "sda", create the parition table and new partition:
  # > parted -s /dev/sda mklabel gpt
  # > parted -s /dev/sda mkpart data btrfs 1MiB 100%
  #
  # Verify it worked and take note of the partition name and UUID. 
  # Update the device attribute in the configuration below to match the UUID.
  # > lsblk -f
  #
  # Assuming the parition is "sda1", format the partition as btrfs:
  # > mkfs.btrfs -fL data /dev/sda1
  #
  # Create the mountpoint and mount the partition:
  # > mkdir -p /mnt/ssd
  # > mount /dev/sda1 /mnt/ssd
  #
  # Create two subvolumes:
  # > btrfs subvolume create /mnt/ssd/snapshots
  # > btrfs subvolume create /mnt/ssd/data
  #
  fileSystems."/mnt/ssd" = {
    fsType = "btrfs"; 
    device = "/dev/disk/by-uuid/7b44d127-729f-43fe-a809-b6aae700c1ab";
    options = btrfs ++ automount;
  };

  fileSystems."/data" = {
    device = "/mnt/ssd/data"; 
    options = bind ++ automount;
  };

  # 4-disk RAID device 
  # -------------------------------------------------------------------------
  # Become root, insert disk and lookup the device name:
  # > sudo -s
  # > lsblk -f
  #
  # Assuming the disk is "sdb", create the parition table and new partition:
  # > parted -s /dev/sdb mklabel gpt
  # > parted -s /dev/sdb mkpart media btrfs 1MiB 100%
  #
  # Verify it worked and take note of the partition name and UUID. 
  # Update the device attribute in the configuration below to match the UUID.
  # > lsblk -f
  #
  # Assuming the parition is "sdb1", format the partition as btrfs:
  # > mkfs.btrfs -fL media /dev/sdb1
  #
  # Create the mountpoint and mount the partition:
  # > mkdir -p /mnt/raid
  # > mount /dev/sdb1 /mnt/raid
  #
  # Create two subvolumes:
  # > btrfs subvolume create /mnt/raid/backups
  # > btrfs subvolume create /mnt/raid/media
  #
  fileSystems."/mnt/raid" = {
    fsType = "btrfs"; 
    device = "/dev/disk/by-uuid/75ae6de3-04d1-4c62-9d15-357038fc4d81";
    options = btrfs ++ automount;  
  };

  fileSystems."/media" = {
    device = "/mnt/raid/media"; 
    options = bind ++ automount;
  };

  fileSystems."/backups" = {
    device = "/mnt/raid/backups"; 
    options = bind ++ automount;
  };

  # # Services that depend on this mount may need the following
  # systemd.services.my-app = {
  #   requires = [ "mnt-raid.mount" ];
  # };

  # Snapshots & backup
  modules.btrbk = {
    enable = true;
    snapshot = {
      "/mnt/ssd".subvolume."data" = {};
    };
    backup = with config.networking; {
      "/mnt/ssd".subvolume."data" = {};
      "/mnt/ssd".target."/backups/${hostName}" = {};
      "/nix".target."/backups/${hostName}" = {};
    };
  };

}
