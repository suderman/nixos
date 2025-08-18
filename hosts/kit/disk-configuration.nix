let
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
  # lsblk -f && ls -1 /dev/disk/by-id | grep '^nvme-eui.*n1$'
  nvme0n1 = "nvme-eui.e8238fa6bf530001001b448b4ca4ccdd"; # below CPU
  nvme1n1 = "nvme-eui.000000000000000100a07524462d7584"; # behind GPU
  nvme2n1 = "nvme-eui.e8238fa6bf530001001b448b4a20d09b"; # behind GPU riser
in {
  # ssd1 is the main disk
  disko.devices.disk.ssd1 = {
    type = "disk"; # below CPU
    device = "/dev/disk/by-id/${nvme0n1}";
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
    content.partitions.part = {
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
  };

  # ssd2 is the data disk
  disko.devices.disk.ssd2 = {
    type = "disk"; # behind GPU
    device = "/dev/disk/by-id/${nvme1n1}";
    content.type = "gpt";
    content.partitions.part = {
      size = "100%";
      content =
        automount "/mnt/data"
        // {
          type = "btrfs";
          extraArgs = ["-fL data"];
          subvolumes = {
            data = automount "/data";
            snapshots = {};
            backups = {};
          };
        };
    };
  };

  # ssd3 is the game disk
  disko.devices.disk.ssd3 = {
    type = "disk"; # behind GPU riser
    device = "/dev/disk/by-id/${nvme2n1}";
    content.type = "gpt";
    content.partitions.part = {
      size = "100%";
      content =
        automount "/mnt/game"
        // {
          type = "btrfs";
          extraArgs = ["-fL data"];
          subvolumes = {
            data = automount "/game";
            snapshots = {};
            backups = {};
          };
        };
    };
  };
}
