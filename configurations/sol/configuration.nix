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
  modules.linode.enable = true;

  # Network
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  networking.extraHosts = "";

  # Memory management
  modules.earlyoom.enable = true;

  # Snapshots & backup
  modules.btrbk.enable = true;

  # Web services
  modules.traefik.enable = true;
  modules.postgresql.enable = true;

  modules.whoogle.enable = false;
  modules.whoami.enable = true;
  modules.sabnzbd.enable = false;

  modules.tandoor-recipes = {
    enable = true;
    public = "tandoor.suderman.net";
  };

  # services.gitea.enable = true;
  # services.gitea.database.type = "mysql";

  # Apps
  modules.neovim.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;

}
