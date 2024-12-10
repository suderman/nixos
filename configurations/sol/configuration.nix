{ config, lib, pkgs, hardware, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [ hardware.linode ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Network
  networking.extraHosts = "";
  services.tailscale.enable = true;
  services.traefik.enable = true;
  services.whoami.enable = true;

  # Custom DNS
  services.blocky.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Apps
  programs.neovim.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;

  # Web services
  services.whoogle = { enable = true; name = "g"; };
  services.tiddlywiki = { enable = true; name = "wiki"; };
  services.rsshub.enable = true;
  services.freshrss.enable = true;

  # Auto restart containers if unheathy
  virtualisation.oci-containers.containers.autoheal = {
    image = "willfarrell/autoheal";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    environment.AUTOHEAL_CONTAINER_LABEL = "all";
  };

}
