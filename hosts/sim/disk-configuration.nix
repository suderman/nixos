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

  disko.devices.disk."1" = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-1";
    content.type = "gpt";

    content.partitions.grub = {
      priority = 1;
      name = "grub";
      size = "1M";
      type = "EF02";
    };

    content.partitions.boot = {
      priority = 2;
      name = "boot";
      size = "512M";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };

    content.partitions.root = {
      priority = 3;
      name = "root";
      size = "100%";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" "-L disk1" ];
        inherit (mount "/disk/1") mountpoint mountOptions;
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

  disko.devices.disk."2" = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-2";
    content.type = "gpt";
    content.partitions.data = {
      name = "data";
      size = "100%";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" "-L disk2" ];
        inherit (automount "/disk/2") mountpoint mountOptions;
        subvolumes = {
          root = automount "/data";
          snapshots = {};
          backups = {};
        };
      };
    };
  };

  disko.devices.disk."3" = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-3";
    content.type = "gpt";
    content.partitions.pool = {
      name = "pool";
      size = "100%";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" "-L disk3" ];
      };
    };
  };

  disko.devices.disk."4" = {
    type = "disk";
    device = "/dev/disk/by-id/virtio-4";
    content.type = "gpt";
    content.partitions.pool = {
      name = "pool";
      size = "100%";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" "-L disk4" "-d single /dev/disk/by-id/virtio-3 /dev/disk/by-id/virtio-4" ];
        inherit (automount "/disk/4") mountpoint mountOptions;
        subvolumes = {
          root = automount "/pool";
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
