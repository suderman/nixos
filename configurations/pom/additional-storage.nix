{ config, ... }: {

  # Additional HDD disk pool
  # -------------------------------------------------------------------------
  # Become root, insert disk and lookup the device name:
  # > sudo -s
  # > lsblk -f
  #
  # Assuming the disks are "sdb-sde", create the parition tables and new partitions:
  # parted -s /dev/sdb mklabel gpt
  # parted -s /dev/sdb mkpart bravo btrfs 1MiB 100%
  # parted -s /dev/sdc mklabel gpt
  # parted -s /dev/sdc mkpart charlie btrfs 1MiB 100%
  # parted -s /dev/sdd mklabel gpt
  # parted -s /dev/sdd mkpart delta btrfs 1MiB 100%
  # parted -s /dev/sde mklabel gpt
  # parted -s /dev/sde mkpart echo btrfs 1MiB 100%
  #
  # Format as btrfs and create the pool
  # mkfs.btrfs -fL pool -d single /dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1
  #
  # Take note of the UUID and mount the pool
  # mkdir -p /mnt/pool
  # mount -t btrfs -o defaults /dev/disk/by-uuid/2b311ebc-75bb-4235-86d9-bc7f57f6820d /mnt/pool
  #
  # Create two subvolumes:
  # > btrfs subvolume create /mnt/pool/backups
  # > btrfs subvolume create /mnt/pool/data

  fileSystems."/mnt/pool" = {
    fsType = "btrfs"; 
    device = "/dev/disk/by-uuid/2b311ebc-75bb-4235-86d9-bc7f57f6820d";
    options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" "x-systemd.automount" ]; 
  };

}
