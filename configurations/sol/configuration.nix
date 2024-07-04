{ config, lib, pkgs, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [ presets.linode ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Network
  networking.extraHosts = "";
  services.tailscale.enable = true;
  services.traefik.enable = true;
  services.whoami.enable = true;

  # Custom DNS
  modules.blocky.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Apps
  programs.neovim.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;

  # Web services
  modules.whoogle = { enable = true; name = "g"; };
  modules.tiddlywiki = { enable = true; name = "wiki"; };
  modules.rsshub.enable = true;
  modules.freshrss.enable = true;

}
