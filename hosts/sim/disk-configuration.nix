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
        "x-systemd.idle-timeout=5m" # unmount after 5 min of inactivity
      ];
  };
  ssd1 = "virtio-1"; # hosts/sim/disk1.img
  ssd2 = "virtio-2"; # hosts/sim/disk2.img
  hdd1 = "virtio-3"; # hosts/sim/disk3.img
  hdd2 = "virtio-4"; # hosts/sim/disk4.img
in rec {
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
        size = "4G";
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
    # data disk
    # disko hosts/sim/disk-configuration.nix --argstr disk ssd2 --mode destroy,format,mount
    // mkDisk "ssd2" {
      device = "/dev/disk/by-id/${ssd2}";
      content.type = "gpt";
      content.partitions.part = let
        label = "data";
      in {
        size = "100%";
        content =
          automount "/mnt/${label}"
          // {
            type = "btrfs";
            extraArgs = ["-fL ${label}"];
            subvolumes = {
              persist = automount "/${label}";
              persist-local = automount "/${label}/local";
              snapshots = {};
              backups = {};
            };
          };
      };
    }
    # hdd1 supports the pool
    # disko hosts/sim/disk-configuration.nix --argstr disk hdd1 --mode destroy,format,mount
    // mkDisk "hdd1" {
      device = "/dev/disk/by-id/${hdd1}";
      content.type = "gpt";
      content.partitions.part = {
        size = "100%";
        content.type = "btrfs";
      };
    }
    # hdd2 supports the pool
    # disko hosts/sim/disk-configuration.nix --argstr disk hdd2 --mode destroy,format,mount
    // mkDisk "hdd2" {
      device = "/dev/disk/by-id/${hdd2}";
      content.type = "gpt";
      content.partitions.part = {
        size = "100%";
        content =
          automount "/mnt/pool"
          // {
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
