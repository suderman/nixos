{ config, lib, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
    ./storage.nix
  ];

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
  modules.whoami.enable = true;
  networking.extraHosts = "";

  # Memory management
  modules.earlyoom.enable = true;

  # Apps
  modules.neovim.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;

  # Web services
  modules.whoogle.enable = true;
  modules.gitea.enable = true;
  modules.tiddlywiki.enable = true;
  modules.rsshub.enable = true;
  modules.freshrss.enable = true;
  modules.tandoor-recipes.enable = true;

  # modules.tandoor-recipes = {
  #   enable = true;
  #   public = "tandoor.suderman.net";
  # };

}
