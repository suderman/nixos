{ config, pkgs, lib, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./storage.nix
  ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Traefik logging
  services.traefik.staticConfigOptions.log.level = "DEBUG";
  
  # Network
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  modules.whoami.enable = true;
  networking.extraHosts = "";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];

    # Ocis
  modules.ocis = { 
    enable = true;
    hostName = "cloud.pingbit.de";
    # dataDir = "/mnt/ocis";
  };
 
  # Immich 
  modules.immich = {
    enable = true;
    hostName = "photos.pingbit.de";
    dataDir = "/mnt/photos";
  };

  modules.silverbullet.enable = true;
  modules.silverbullet.hostName = "wiki.pingbit.de";
  
  modules.netdata.enable = true;
}

# Ideas / todos:
# use https://github.com/berberman/nvfetcher to update docker images