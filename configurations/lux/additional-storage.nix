{ config, lib, pkgs, inputs, ... }: {

  # Additional data disk
  fileSystems."/mnt/ssd" =
    { device = "/dev/disk/by-uuid/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
      fsType = "btrfs";
      options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];
    };
  fileSystems."/data" = { device = "/mnt/ssd/data"; options = [ "bind" ]; };

  # 4-disk RAID device 
  fileSystems."/mnt/raid" =
    { device = "/dev/disk/by-uuid/75ae6de3-04d1-4c62-9d15-357038fc4d81";
      fsType = "btrfs";
      options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];
    };
  fileSystems."/media" = { device = "/mnt/raid/media"; options = [ "bind" ]; };

}
