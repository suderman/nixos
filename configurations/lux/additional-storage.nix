{ config, ... }: let 

  btrfs = { 
    fsType = "btrfs"; 
    options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ]; 
  };

  bind = { options = [ "bind" ]; };

in {

  fileSystems = {

    # Additional data disk
    "/mnt/ssd" = btrfs // { device = "/dev/disk/by-uuid/7b44d127-729f-43fe-a809-b6aae700c1ab"; };
    "/data" = bind // { device = "/mnt/ssd/data"; };

    # 4-disk RAID device 
    "/mnt/raid" = btrfs // { device = "/dev/disk/by-uuid/75ae6de3-04d1-4c62-9d15-357038fc4d81"; };
    "/media" = bind // { device = "/mnt/raid/media"; };

  };

}
