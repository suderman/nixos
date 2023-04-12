{ config, lib, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  # Btrfs mount options
  fileSystems."/".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];
  fileSystems."/nix".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];

  # Base configuration
  modules.base.enable = true;
  modules.secrets.enable = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hardware configuration
  hardware.linode.enable = true;

  # Network
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.openssh.enable = true;
  networking.extraHosts = "";

  # Memory management
  services.earlyoom.enable = true;

  # Snapshots & backup
  services.btrbk.enable = true;

  # Web services
  modules.traefik.enable = true;
  modules.postgresql.enable = true;

  services.whoogle.enable = false;
  services.whoami.enable = true;
  services.sabnzbd.enable = false;

  services.tandoor-recipes = {
    enable = true;
    public = "tandoor.suderman.net";
  };

  # services.gitea.enable = true;
  # services.gitea.database.type = "mysql";

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;
  programs.tmux.enable = true;

}
