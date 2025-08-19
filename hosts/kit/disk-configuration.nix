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
  # lsblk -f && ls -1 /dev/disk/by-id | grep '^nvme-eui.*n1$'
  nvme0n1 = "nvme-eui.e8238fa6bf530001001b448b4ca4ccdd"; # below CPU
  nvme1n1 = "nvme-eui.000000000000000100a07524462d7584"; # behind GPU
  nvme2n1 = "nvme-eui.e8238fa6bf530001001b448b4a20d09b"; # behind GPU riser
in {
  disko.devices.disk =
    # main disk
    # disko hosts/kit/disk-configuration.nix --argstr disk ssd1 --mode destroy,format,mount
    mkDisk "ssd1" {
      device = "/dev/disk/by-id/${nvme0n1}"; # below CPU
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
    # data disk
    # disko hosts/kit/disk-configuration.nix --argstr disk ssd2 --mode destroy,format,mount
    // mkDisk "ssd2" {
      device = "/dev/disk/by-id/${nvme1n1}"; # behind GPU
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
    # game disk
    # disko hosts/kit/disk-configuration.nix --argstr disk ssd3 --mode destroy,format,mount
    // mkDisk "ssd3" {
      device = "/dev/disk/by-id/${nvme2n1}"; # behind GPU riser
      content.type = "gpt";
      content.partitions.part = let
        label = "game";
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
    };
}
