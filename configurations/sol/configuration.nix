{ config, lib, pkgs, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [ presets.linode ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # # Hardware configuration
  # modules.linode.enable = true;

  # Network
  modules.tailscale.enable = true;
  # modules.ddns.enable = true;
  # modules.traefik.enable = true;

  modules.traefik = {
    enable = true;
    routers."wiki.zz" = "https://wiki.sol";
    extraInternalHostNames = [ "wiki.zz" ];
  };

  modules.whoami.enable = true;
  networking.extraHosts = "";

  # Custom DNS
  modules.blocky.enable = true;

  # Memory management
  modules.earlyoom.enable = true;

  # Apps
  modules.neovim.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;

  # Web services
  modules.whoogle = { enable = true; name = "g"; };
  # modules.gitea = { enable = true; name = "git"; };
  modules.tiddlywiki = { enable = true; name = "wiki"; };
  modules.rsshub.enable = true;
  modules.freshrss.enable = true;
  # modules.wallabag.enable = false;
  # modules.nextcloud.enable = false;

  # modules.tandoor-recipes = {
  #   enable = false;
  #   # package = pkgs.unstable.tandoor-recipes;
  #   # public = "tandoor.suderman.net";
  # };

}
