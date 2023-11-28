{ config, pkgs, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./storage.nix
  ];

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
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  modules.whoami.enable = true;

  modules.cockpit.enable = true;

  modules.bluebubbles.enable = true;

  modules.plex.enable = true;
  modules.tautulli.enable = true;
  modules.jellyfin.enable = true;

  modules.silverbullet.enable = true;

  modules.lunasea.enable = true;
  modules.sabnzbd.enable = true;
  modules.radarr.enable = true;
  modules.sonarr.enable = true;
  modules.lidarr.enable = true;
  modules.ombi.enable = true;

  modules.nextcloud.enable = true;
  modules.ocis.enable = true;
  modules.gitea.enable = true;
  modules.tiddlywiki.enable = true;
  modules.wallabag.enable = false;

  modules.freshrss.enable = true;
  modules.tandoor-recipes.enable = false;

  modules.immich = {
    enable = true;
    photosDir = "/data/photos/immich";
  };

  modules.photoprism = {
    enable = false;
    photosDir = "/data/photos";
  };

}
