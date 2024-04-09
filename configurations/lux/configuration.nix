{ config, pkgs, this, ... }: {

  # Import all *.nix files in this directory
  imports = this.lib.ls ./.;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Memory management
  modules.earlyoom.enable = true;

  # Keyboard control
  modules.keyd.enable = true;
  modules.ydotool.enable = true;

  # Apps
  programs.mosh.enable = true;
  modules.neovim.enable = true;

  # Web services
  modules.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };
  modules.traefik.enable = true;
  modules.prometheus.enable = true;
  modules.whoami.enable = true;
  modules.cockpit.enable = true;

  modules.silverbullet.enable = true;
  modules.gitea.enable = true; 
  modules.ollama.enable = true;

  modules.jellyfin.enable = true;
  modules.plex.enable = true;

  modules.lunasea.enable = true;
  modules.sabnzbd = { enable = true; name = "sab"; };
  modules.radarr.enable = true;
  modules.sonarr.enable = true;
  modules.lidarr.enable = true;
  modules.ombi = {
    enable = true;
    alias = { 
      hostName = "ombi.suderman.org"; 
      public = false; 
    };
  };

  modules.ocis = {
    enable = true;
    hostName = "ocis.suderman.org";
    public = false;
  };
  
  modules.immich = {
    enable = true;
    photosDir = "/data/photos/immich";
    externalDir = "/data/photos/collections";
    alias = { 
      hostName = "immich.suderman.org"; 
      public = false; 
    };
  };
  
  # modules.photoprism = {
  #   enable = false;
  #   photosDir = "/data/photos";
  # };
  # modules.tiddlywiki = { enable = true; name = "wiki"; };
  # modules.wallabag.enable = false;
  # modules.freshrss.enable = true;
  # modules.tandoor-recipes.enable = false;
  # modules.nextcloud.enable = false;

}
