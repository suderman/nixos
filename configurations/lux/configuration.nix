{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./additional-storage.nix
  ];

  # Btrfs mount options
  fileSystems."/".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];
  fileSystems."/nix".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];

  modules.base.enable = true;
  modules.secrets.enable = true;

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

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  # Web services
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.whoami.enable = true;
  services.tautulli.enable = true;
  services.jellyfin.enable = true;

  modules.plex.enable = true;

  modules.immich = {
    enable = true;
    dataDir = "/data/immich";
  };

  modules.sabnzbd.enable = true;
  # modules.radarr.enable = true;

  # /data/immich
  # /media/movies

  # # Snapshot photos subvolume stored on /data
  # services.btrbk.instances.local.settings = {
  #   volume."/mnt/ssd" = {
  #     snapshot_dir = "snapshots";
  #     target = "/mnt/raid/backups/lux";
  #     subvolume."data".snapshot_preserve = "48h 7d 4w";
  #   };
  # };
}
