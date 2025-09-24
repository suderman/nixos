{disks ? [], ...}: let
  # Named disk devices
  # lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK
  dev = {
    ssd1 = "nvme-WD_BLACK_SN850X_1000GB_23436M800093"; # system disk
    ssd2 = "wwn-0x500a0751e66bd3cc"; # data disk
    hdd1 = "ata-JMicron_H_W_RAID10_UQ1BYN7MPUY9LJBTHD6X"; # 4-bay raid
  };

  # Create named disk attr if name found in disks list OR if disks is empty list
  disk = name: partitions:
    if disks == [] || (builtins.hasAttr name dev && builtins.elem name disks)
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
        size = "32G";
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
              scratch = {};
              storage = {};
              snapshots = {};
              backups = {};
            };
          };
      };
    }
    # data disk
    # disko disk-configuration.nix -m destroy,format,mount --arg disks '["ssd2"]'
    // disk "ssd2" {
      part = {
        size = "100%";
        content =
          automount "/mnt/data"
          // {
            type = "btrfs";
            extraArgs = ["-fL data"];
            subvolumes = {
              storage = automount "/data";
              snapshots = {};
              backups = {};
            };
          };
      };
    }
    # hdd1 is 4-bay raid
    # disko disk-configuration.nix -m destroy,format,mount --arg disks '["hdd1"]'
    // disk "hdd1" {
      part = {
        size = "100%";
        content =
          automount "/mnt/pool"
          // {
            type = "btrfs";
            extraArgs = ["-fL pool"];
            subvolumes = {
              storage = automount "/media";
              snapshots = {};
              backups = {};
            };
          };
      };
    };
}
