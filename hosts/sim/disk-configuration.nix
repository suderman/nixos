{ config, flake, pkgs, ... }: let 

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

in {

  disko.devices.disk.disk1 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-1";
    content.type = "gpt";

    content.partitions.grub = {
      name = "grub";
      size = "1M";
      type = "EF02";
      priority = 1;
    };

    content.partitions.boot = {
      name = "boot";
      size = "512M";
      type = "EF00";
      priority = 2;
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };

    content.partitions.swap = {
      size = "4G";
      priority = 3;
      content = {
        type = "swap";
        discardPolicy = "both";
        resumeDevice = true; # support hibernation
      };
    };

    content.partitions.disk1 = {
      name = "disk1";
      size = "100%";
      priority = 4;
      content = mount "/disk/disk1" // {
        type = "btrfs";
        extraArgs = [ "-fL disk1" ];
        subvolumes = {
          root = mount "/";
          persist = mount "/persist";
          nix = mount "/nix";
          snapshots = {};
          backups = {};
        };
      };
    };
  };

  disko.devices.disk.disk2 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-2";
    content.type = "gpt";
    content.partitions.disk2 = {
      name = "disk2";
      size = "100%";
      content = automount "/disk/disk2" // {
        type = "btrfs";
        extraArgs = [ "-fL disk2" ];
        subvolumes = {
          data = automount "/data";
          snapshots = {};
          backups = {};
        };
      };
    };
  };

  disko.devices.disk.disk3 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-3";
    content.type = "gpt";
    content.partitions.disk3 = {
      name = "disk3";
      size = "100%";
      content.type = "btrfs";
    };
  };

  disko.devices.disk.disk4 = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-4";
    content.type = "gpt";
    content.partitions.disk4 = {
      name = "disk4";
      size = "100%";
      content = automount "/disk/disk34" // {
        type = "btrfs";
        extraArgs = [ 
          "-fL disk34" 
          "-d single /dev/disk/by-id/virtio-3-part1 /dev/disk/by-id/virtio-4-part1"
        ];
        subvolumes = {
          snapshots = {};
          backups = {};
        };
      };
    };
  };



  # # Snapshots & backups
  # services.btrbk = {
  #   # enable = false;
  #   # backups = with config.networking; {
  #   #   "/nix".target."ssh://fit/backups/${hostName}" = {};
  #   #   # "/nix".target."ssh://eve/backups/${hostName}" = {}; # re-enable after eve is healthy again
  #   # };
  # };



}
