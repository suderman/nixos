{
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.default
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Always at work next to my desk
  networking.domain = "work";

  # Allow other devices on my LAN to access my tailnet
  services.tailscale.extraSetFlags = ["--advertise-routes=10.2.0.0/16"];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [];
    "/mnt/pool" = [];
  };

  # Serve CA cert on http://10.2.0.2:1234
  services.traefik.caPort = 1234;

  # # Backup media server
  # services.jellyfin.enable = true;
  #
  # # Point /media to /backups/lux/media.* (latest version)
  # systemd.services.media-symlink = {
  #   description = "Update /media to point to latest lux backup";
  #   after = ["multi-user.target"];
  #   requires = ["multi-user.target"];
  #   wantedBy = ["sysinit.target"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #   };
  #   path = with pkgs; [coreutils];
  #   script = ''
  #     rm -f /media
  #     ln -s "$(ls -td /backups/lux/media.* | head -n1)" /media
  #   '';
  # };
  #
  # # Run this script every day
  # systemd.timers."media-symlink" = {
  #   wantedBy = ["timers.target"];
  #   partOf = ["media-symlink.service"];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Unit = "media-symlink.service";
  #   };
  # };
}
