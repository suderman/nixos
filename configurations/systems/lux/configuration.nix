{ config, lib, pkgs, this, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    profiles.services
    profiles.terminal
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  services.prometheus.enable = true;
  services.gitea.enable = true; 
  services.jellyfin.enable = true;
  services.plex.enable = true;
  services.lunasea.enable = true;
  
  services.immich = {
    enable = true;
    photosDir = "/data/photos/immich";
    externalDir = "/data/photos/collections";
    alias = "immich.suderman.org"; 
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings.media = {
      path = "/media";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      comment = "Media";
    };
  };

  # Allows Windows clients to discover server
  services.samba-wsdd.enable = true;

}
