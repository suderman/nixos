{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    # ./storage.nix
  ];

  modules.base.enable = true;
  modules.secrets.enable = true;

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

  modules.rclone.enable = true;
  modules.rclone.configPath = config.age.secrets.rclone-conf.path;
  modules.rclone.remote = "azure-data:photos";
  modules.rclone.mountPath = "/mnt/photos";


  # Web services
  modules.ocis.enable = true;
  modules.ocis.hostName = "cloud.pingbit.de";

  modules.immich = {
    enable = true;
    hostName = "photos.pingbit.de";
    photosDir = "/mnt/photos";
  };
}
