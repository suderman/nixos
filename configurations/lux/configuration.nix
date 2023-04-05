{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./additional-storage.nix
  ];

  # Btrfs mount options
  fileSystems."/".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];
  fileSystems."/nix".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];

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
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  services.plex.enable = true;
  services.tautulli.enable = true;
  services.jellyfin.enable = true;

}
