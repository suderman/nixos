{disk ? "all", ...}: let
  mkDisk = diskName: cfg:
    if disk == "all" || disk == diskName
    then {"${diskName}" = {type = "disk";} // cfg;}
    else {};

  mount = mountpoint: {
    inherit mountpoint;
    mountOptions = [
      "compress=zstd" # enable zstd compression
      "space_cache=v2" # track available free space on filesystem
      "discard=async" # free up deleted space in the background
      "noatime" # disables access time updates on files
    ];
  };

  automount = mountpoint: {
    inherit mountpoint;
    mountOptions =
      (mount null).mountOptions
      ++ [
        "noauto" # do not mount on boot
        "nofail" # continue boot even if disk is missing
        "x-systemd.automount" # create automount unit to mount when accessed
        "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
        "x-systemd.idle-timout=5m" # unmount after 5 min of inactivity
      ];
  };
  ssd1 = "ata-WDC_WDS500G2B0A-00SM50_181703805719";
  hdd1 = "ata-ST12000NM0538-2K2101_ZHZ29F82";
  hdd2 = "ata-ST12000NM0538-2K2101_ZHZ5F9VF";
in {
  # ssd1 is the main disk
  disko.devices.disk =
    # main disk
    # disko hosts/sim/disk-configuration.nix --argstr disk ssd1 --mode destroy,format,mount
    mkDisk "ssd1" {
      device = "/dev/disk/by-id/${ssd1}";
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
          mountOptions = ["umask=0077"];
        };
      };

      # adjust size to match ram
      content.partitions.swap = {
        size = "8G";
        priority = 3;
        content = {
          type = "swap";
          discardPolicy = "both";
          resumeDevice = true; # support hibernation
        };
      };

      # main partition
      content.partitions.part = let
        label = "main";
      in {
        size = "100%";
        priority = 4;
        content =
          mount "/mnt/${label}"
          // {
            type = "btrfs";
            extraArgs = ["-fL ${label}"];
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
    }
    # hdd1 supports the pool
    # disko hosts/eve/disk-configuration.nix --argstr disk hdd1 --mode destroy,format,mount
    // mkDisk "hdd1" {
      device = "/dev/disk/by-id/${hdd1}";
      content.type = "gpt";
      content.partitions.part = {
        size = "100%";
        content.type = "btrfs";
      };
    }
    # hdd2 supports the pool
    # disko hosts/eve/disk-configuration.nix --argstr disk hdd2 --mode destroy,format,mount
    // mkDisk "hdd2" {
      device = "/dev/disk/by-id/${hdd2}";
      content.type = "gpt";
      content.partitions.part = {
        size = "100%";
        content =
          automount "/mnt/pool"
          // {
            type = "btrfs";
            extraArgs = [
              "-fL pool"
              "-d single"
              "/dev/disk/by-id/${hdd1}-part1"
              "/dev/disk/by-id/${hdd2}-part1"
            ];
            subvolumes = {
              snapshots = {};
              backups = {};
            };
          };
      };
    };
}
