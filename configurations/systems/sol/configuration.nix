{ config, lib, pkgs, hardware, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.linode
    profiles.services
    profiles.terminal
  ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Custom DNS
  services.blocky.enable = true;

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
