{disks ? [], ...}: let
  # Named disk devices
  dev = {
    ssd1 = "virtio-1"; # hosts/sim/disk1.img
    ssd2 = "virtio-2"; # hosts/sim/disk2.img
    hdd1 = "virtio-3"; # hosts/sim/disk3.img
    hdd2 = "virtio-4"; # hosts/sim/disk4.img
  };

  # Create named disk attr if name found in disks list OR if disks is empty list
  disk = name: partitions:
    if disks == [] || builtins.elem name disks
    then {
      "${name}" = {
        type = "disk";
        device = "/dev/disk/by-id/${builtins.getAttr name dev}";
        content = {
          type = "gpt";
          inherit partitions;
        };
      };
    }
    else {};

  # Default btrfs mount options with mountpoint
  mount = mountpoint: {
    inherit mountpoint;
    mountOptions = [
      "compress=zstd" # enable zstd compression
      "space_cache=v2" # track available free space on filesystem
      "discard=async" # free up deleted space in the background
      "noatime" # disables access time updates on files
    ];
  };

  # Extended mount options to support automount
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
in {
  disko.devices.disk =
    # main disk
    # disko disk-configuration.nix -m destroy,format,mount --arg disks '["ssd1"]'
    disk "ssd1" {
      # bios boot
      grub = {
        size = "1M";
        type = "EF02";
        priority = 1;
      };

      # uefi boot
      boot = {
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
      swap = {
        size = "4G";
        priority = 3;
        content = {
          type = "swap";
          discardPolicy = "both";
          resumeDevice = true; # support hibernation
        };
      };

      # main partition
      part = {
        size = "100%";
        priority = 4;
        content =
          mount "/mnt/main"
          // {
            type = "btrfs";
            extraArgs = ["-fL main"];
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
    # disko hosts/sim/disk-configuration.nix -m destroy,format,mount --arg disks '["ssd2"]'
    // disk "ssd2" {
      part = {
        size = "100%";
        content =
          automount "/mnt/data"
          // {
            type = "btrfs";
            extraArgs = ["-fL data"];
            subvolumes = {
              persist = automount "/data";
              persist-local = automount "/data/local";
              snapshots = {};
              backups = {};
            };
          };
      };
    }
    # hdd1,hdd2 make up the pool
    # disko disk-configuration.nix -m destroy,format,mount --arg disks '["hdd1" "hdd2"]'
    // disk "hdd1" {
      part = {
        size = "100%";
        content.type = "btrfs";
      };
    }
    // disk "hdd2" {
      part = {
        size = "100%";
        content =
          automount "/mnt/pool"
          // {
            type = "btrfs";
            extraArgs = [
              "-fL pool"
              "-d single"
              "/dev/disk/by-id/${dev.hdd1}-part1"
              "/dev/disk/by-id/${dev.hdd2}-part1"
            ];
            subvolumes = {
              snapshots = {};
              backups = {};
            };
          };
      };
    };
}
