{ config, lib, pkgs, this, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./.;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  # Web services
  services.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };

  services.traefik.enable = true;
  services.prometheus.enable = true;
  services.whoami.enable = true;

  services.silverbullet.enable = true;
  services.gitea.enable = true; 

  services.jellyfin.enable = true;
  services.plex.enable = true;
  services.lunasea.enable = true;

  services.ocis = {
    enable = true;
    hostName = "ocis.suderman.org";
    public = false;
  };
  
  services.immich = {
    enable = true;
    photosDir = "/data/photos/immich";
    externalDir = "/data/photos/collections";
    alias = { 
      hostName = "immich.suderman.org"; 
      public = false; 
    };
  };

}
