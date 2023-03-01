{ inputs, config, lib, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  fileSystems."/".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" "subvol=root" ];
  fileSystems."/nix".options = [ "compress=zstd" "space_cache=v2" "discard=async" "noatime" ];

  base.enable = true;
  state.enable = true;
  secrets.enable = true;

  # Hardware configuration
  hardware.linode.enable = true;

  # Network
  services.tailscale.enable = true;
  services.ddns.enable = true;
  services.openssh.enable = true;
  networking.extraHosts = "";

  # Memory management
  services.earlyoom.enable = true;

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
  programs.mosh.enable = true;
  programs.neovim.enable = true;
  programs.tmux.enable = true;

}
