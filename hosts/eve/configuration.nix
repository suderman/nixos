{
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.common
    flake.nixosModules.extra
  ];

  config = {
    networking.domain = "work";
    networking.firewall.allowPing = true;

    # Use freshest kernel
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

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

    # # Snapshots & backup
    # services.btrbk.enable = true;
    #
    # # Additional filesystems in motd
    # programs.rust-motd.settings.filesystems = {
    #   pool = "/mnt/pool";
    # };
  };
}
