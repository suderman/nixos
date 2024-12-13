{ config, lib, pkgs, this, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./.;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  # Web services
  services.tailscale.enable = true;
  services.whoami.enable = true;

  # Custom DNS
  services.blocky.enable = true;

  # Serve CA cert on http://10.2.0.2:1234
  services.traefik = {
    enable = true;
    caPort = 1234;
  };

  # Reverse proxy bluebubbles server on nearby Mac Mini
  services.bluebubbles = with this.networks; {
    enable = true;
    name = "bb";
    # ip = work.pom;
    # ip = work.bub;
    ip = home.bub;
  };

  # Backup media server
  services.jellyfin.enable = true;

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
