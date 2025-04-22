{ config, flake, pkgs, ... }: let 
  inherit (config.disko.lib) mnt;
in {

  disko.devices.disk.ssd1 = {
    type = "disk";
    device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
    content.type = "gpt";

    content.partitions.boot = {
      priority = 1;
      name = "boot";
      start = "1M";
      end = "128M";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };

    content.partitions.data = {
      priority = 2;
      name = "data";
      size = "100%";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" ];
        inherit (mnt "/mnt/ssd1") mountpoint mountOptions;
        subvolumes = {
          root = mnt "/";
          persist = mnt "/persist";
          nix = mnt "/nix";
          snapshots = {};
          backups = {};
        };
      };
    };
  };

  # Snapshots & backups
  services.btrbk = {
    # enable = false;
    # backups = with config.networking; {
    #   "/nix".target."ssh://fit/backups/${hostName}" = {};
    #   # "/nix".target."ssh://eve/backups/${hostName}" = {}; # re-enable after eve is healthy again
    # };
  };

}
