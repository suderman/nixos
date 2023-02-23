{ config, lib, pkgs, inputs, ... }: {

  imports = [ 
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework 
  ];

  # root is tmpfs
  fileSystems."/" = { 
    # device = "none"; fsType = "tmpfs";
    options = [ "size=8G" "mode=755" ]; # limit to 8GB and only writable by root
  };

  # /nix is btrfs
  fileSystems."/nix" = { 
    # device = "/dev/disk/by-uuid/xxx"; fsType = "btrfs";
    options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ]; # btrfs mount options
    neededForBoot = true; 
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Base configuration
  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Desktop Environments
  desktops.gnome.enable = true;

  # Network
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.openssh.enable = true;
  networking.extraHosts = "";

  # Broken? Prevents boot.
  # services.sunshine.enable = false;

  # Memory management
  # services.earlyoom.enable = true;

  # Fingerprint reader
  services.fprintd.enable = true;

  # Keyboard control
  services.keyd.enable = true;
  services.ydotool.enable = true;

  # Database services
  services.mysql.enable = true;
  services.postgresql.enable = false;
  
  # Web services
  services.traefik.enable = true;
  services.whoogle.enable = false;
  services.whoami.enable = true;
  services.sabnzbd.enable = false;
  services.tandoor-recipes.enable = false;
  # services.gitea.enable = true;
  # services.gitea.database.type = "mysql";

  # Apps
  services.flatpak.enable = true;
  programs.mosh.enable = true;
  programs.neovim.enable = true;
  programs.steam.enable = false;

}
