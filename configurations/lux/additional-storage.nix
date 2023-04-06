{ config, ... }: let 

  # These disks aren't automatically added by the installer and must be added manually.
  btrfs = { 
    fsType = "btrfs"; 
    options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ]; 
  };
  bind = { options = [ "bind" ]; };

in {

  fileSystems = {

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
    "/mnt/ssd" = btrfs // { device = "/dev/disk/by-uuid/7b44d127-729f-43fe-a809-b6aae700c1ab"; };
    "/data" = bind // { device = "/mnt/ssd/data"; };

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
    "/mnt/raid" = btrfs // { device = "/dev/disk/by-uuid/75ae6de3-04d1-4c62-9d15-357038fc4d81"; };
    "/media" = bind // { device = "/mnt/raid/media"; };

  };

}
