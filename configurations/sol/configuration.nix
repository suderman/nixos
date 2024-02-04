{ config, lib, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
    ./storage.nix
  ];

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
  modules.cockpit.enable = true;
  modules.whoogle = { enable = true; name = "g"; };
  modules.gitea = { enable = true; name = "git"; };
  modules.tiddlywiki = { enable = true; name = "wiki"; };
  modules.rsshub.enable = true;
  modules.freshrss.enable = true;
  modules.wallabag.enable = false;
  # modules.nextcloud.enable = false;

  modules.tandoor-recipes = {
    enable = false;
    # package = pkgs.unstable.tandoor-recipes;
    # public = "tandoor.suderman.net";
  };

}
