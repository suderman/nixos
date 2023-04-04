{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
  ];

  fileSystems."/mnt/ssd" =
    { device = "/dev/disk/by-uuid/e3591e1c-e091-4e16-b55f-088ab195fec4";
      fsType = "btrfs";
    };

  fileSystems."/mnt/raid" =
    { device = "/dev/disk/by-uuid/e3591e1c-e091-4e16-b55f-088ab195fec4";
      fsType = "btrfs";
    };


  fileSystems."/data/media" = {
    device = "/mnt/raid/media";
    options = [ "bind" ];
  };

  fileSystems."/data" = {
    device = "/mnt/ssd/data";
    options = [ "bind" ];
  };

  # /data/immich
  # /media/movies

  # # /srv/snaps
  # # /srv/data
  # # /srv/data/immich
  # # /srv/data/photoprism
  # # /srv/data/library (historical)
  # fileSystems."/srv" =
  #   { device = "/dev/disk/by-uuid/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
  #     fsType = "btrfs";
  #   };
  #
  # # mount raid subvolume 
  # fileSystems."/srv/media" =
  #   { device = "/dev/disk/by-uuid/75ae6de3-04d1-4c62-9d15-357038fc4d81";
  #     fsType = "btrfs";
  #     options = [ "subvol=@media" ];
  #   };
  #
  # # mount raid subvolume 
  # fileSystems."/srv/archive" =
  #   { device = "/dev/disk/by-uuid/75ae6de3-04d1-4c62-9d15-357038fc4d81";
  #     fsType = "btrfs";
  #     options = [ "subvol=@archive" ];
  #   };

  # # Snapshot photos subvolume stored on /data
  # services.btrbk.instances.local.settings = {
  #   volume."/mnt/ssd" = {
  #     snapshot_dir = "snapshots";
  #     target = "/mnt/raid/backups/lux";
  #     subvolume."data".snapshot_preserve = "48h 7d 4w";
  #   };
  # };

  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Configure the SSH daemon
  services.openssh.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Snapshots & backup
  services.btrbk.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;
  services.ydotool.enable = true;

  # Web services
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.traefik.enable = true;
  services.whoami.enable = true;

  # Desktop Environments
  desktops.gnome.enable = true;

  # Apps
  services.flatpak.enable = true;
  programs.mosh.enable = true;
  programs.neovim.enable = true;

}
