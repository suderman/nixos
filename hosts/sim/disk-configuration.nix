let 

  mount = mountpoint: {
    inherit mountpoint;
    mountOptions = [
      "compress=zstd"  # enable zstd compression
      "space_cache=v2" # track available free space on filesystem
      "discard=async"  # free up deleted space in the background
      "noatime"        # disables access time updates on files
    ];
  };

  automount = mountpoint: {
    inherit mountpoint;
    mountOptions = (mount null).mountOptions ++ [
      "noauto"                       # do not mount on boot
      "nofail"                       # continue boot even if disk is missing
      "x-systemd.automount"          # create automount unit to mount when accessed
      "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
      "x-systemd.idle-timout=5m"     # unmount after 5 min of inactivity
    ];
  };

in rec {

  # ssd1 is the main disk
  disko.devices.disk.ssd1 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-1";
    content.type = "gpt";

    # bios boot
    content.partitions.grub = {
      size = "1M";
      type = "EF02";
      priority = 1;
    };

    # uefi boot
    content.partitions.boot = {
      size = "4G";
      type = "EF00";
      priority = 2;
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };

    # adjust size to match ram
    content.partitions.swap = {
      size = "4G";
      priority = 3;
      content = {
        type = "swap";
        discardPolicy = "both";
        resumeDevice = true; # support hibernation
      };
    };

    # main partition
    content.partitions.part = {
      size = "100%";
      priority = 4;
      content = mount "/mnt/main" // {
        type = "btrfs";
        extraArgs = [ "-fL main" ];
        subvolumes = {
          root = mount "/";
          nix = mount "/nix";
          persist = mount "/persist";
          persist-local = mount "/persist/local";
          snapshots = {};
          backups = {};
        };
      };
    };
  };

  # ssd2 is the data disk
  disko.devices.disk.ssd2 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-2";
    content.type = "gpt";
    content.partitions.part = {
      size = "100%";
      content = automount "/mnt/data" // {
        type = "btrfs";
        extraArgs = [ "-fL data" ];
        subvolumes = {
          data = automount "/data";
          snapshots = {};
          backups = {};
        };
      };
    };
  };

  # hdd1 supports the pool
  disko.devices.disk.hdd1 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-3";
    content.type = "gpt";
    content.partitions.part = {
      size = "100%";
      content.type = "btrfs";
    };
  };

  # hdd2 supports the pool
  disko.devices.disk.hdd2 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-4";
    content.type = "gpt";
    content.partitions.part = {
      size = "100%";
      content = automount "/mnt/pool" // {
        type = "btrfs";
        extraArgs = with disko.devices.disk; [ 
          "-fL pool" 
          "-d single"
          "${hdd1.device}-part1"
          "${hdd2.device}-part1"
        ];
        subvolumes = {
          snapshots = {};
          backups = {};
        };
      };
    };
  };

}
