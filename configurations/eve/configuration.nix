{ config, pkgs, this, ... }: {

  imports = [ 
    ./hardware-configuration.nix
    ./storage.nix
  ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

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
  modules.blocky.enable = true;
  # modules.ddns.enable = true;
  modules.whoami.enable = true;
  modules.cockpit.enable = true;

  # Reverse proxy bluebubbles server on nearby Mac Mini
  modules.bluebubbles = with this.network.dns; {
    enable = true;
    name = "bb";
    ip = work.pom;
  };

  # Reverse proxy for router
  modules.traefik = with this.network.dns; {
    enable = true;
    routers.rt = "https://${work.rt}:10443";
  };

  # Backup media server
  modules.jellyfin.enable = true;

  # Point /media to /backups/lux/media.* (latest version) 
  systemd.services.media-symlink = {
    description = "Update /media to point to latest lux backup";
    after = [ "multi-user.target" ];
    requires = [ "multi-user.target" ];
    wantedBy = [ "sysinit.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    path = with pkgs; [ coreutils ];
    script = ''
      rm -f /media
      ln -s "$(ls -td /backups/lux/media.* | head -n1)" /media
    '';
  };

  # Run this script every day
  systemd.timers."media-symlink" = {
    wantedBy = [ "timers.target" ];
    partOf = [ "media-symlink.service" ];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "media-symlink.service";
    };
  };

}
