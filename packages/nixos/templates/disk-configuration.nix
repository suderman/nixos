# lsblk -o ID-LINK,NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS --tree=ID-LINK | \ssh x0.at
{disks ? [], ...}: let
  # Named disk devices
  ssd1 = "REPLACE_WITH_SYSTEM_DISK_ID"; # system disk
  # ssd2 = "REPLACE_WITH_ID_2";
  # hdd1 = "REPLACE_WITH_ID_3";
  # hdd2 = "REPLACE_WITH_ID_4";

  # Create named disk attr if name found in disks list OR if disks is empty list
  disk = name: cfg:
    if disks == [] || builtins.elem name disks
    then {"${name}" = {type = "disk";} // cfg;}
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
  # # Extended mount options to support automount
  # automount = mountpoint: {
  #   inherit mountpoint;
  #   mountOptions =
  #     (mount null).mountOptions
  #     ++ [
  #       "noauto" # do not mount on boot
  #       "nofail" # continue boot even if disk is missing
  #       "x-systemd.automount" # create automount unit to mount when accessed
  #       "x-systemd.device-timeout=1ms" # assume device is already plugged in and do not wait
  #       "x-systemd.idle-timeout=5m" # unmount after 5 min of inactivity
  #     ];
  # };
in {
  disko.devices.disk =
    # main disk
    # disko disk-configuration.nix -m destroy,format,mount --arg disks '["ssd1"]'
    disk "ssd1" {
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
        label = "main"; # system disk
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
    };
  # # data disk
  # # disko disk-configuration.nix -m destroy,format,mount --arg disks '["ssd2"]'
  # // disk "ssd2" {
  #   device = "/dev/disk/by-id/${ssd2}";
  #   content.type = "gpt";
  #   content.partitions.part = let
  #     label = "data"; # data example
  #   in {
  #     size = "100%";
  #     content =
  #       automount "/mnt/${label}"
  #       // {
  #         type = "btrfs";
  #         extraArgs = ["-fL ${label}"];
  #         subvolumes = {
  #           persist = automount "/${label}";
  #           persist-local = automount "/${label}/local";
  #           snapshots = {};
  #           backups = {};
  #         };
  #       };
  #   };
  # }
  # # hdd1,hdd2 make up the pool
  # # disko disk-configuration.nix -m destroy,format,mount --arg disks '["hdd1" "hdd2"]'
  # // disk "hdd1" {
  #   device = "/dev/disk/by-id/${hdd1}";
  #   content.type = "gpt";
  #   content.partitions.part = {
  #     size = "100%";
  #     content.type = "btrfs";
  #   };
  # }
  # // disk "hdd2" {
  #   device = "/dev/disk/by-id/${hdd2}";
  #   content.type = "gpt";
  #   content.partitions.part = let
  #     label = "pool"; # pool example
  #   in {
  #     size = "100%";
  #     content =
  #       automount "/mnt/${label}"
  #       // {
  #         type = "btrfs";
  #         extraArgs = [
  #           "-fL ${label}"
  #           "-d single"
  #           "/dev/disk/by-id/${hdd1}-part1"
  #           "/dev/disk/by-id/${hdd2}-part1"
  #         ];
  #         subvolumes = {
  #           snapshots = {};
  #           backups = {};
  #         };
  #       };
  #   };
  # };
}
