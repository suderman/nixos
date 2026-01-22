{
  config,
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

  # Always at home in my laundry room
  networking.domain = "home";

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [
      "ssh://pow/mnt/pool/backups/${config.networking.hostName}"
      "ssh://eve/mnt/pool/backups/${config.networking.hostName}"
    ];
    "/mnt/data" = [
      "ssh://pow/mnt/pool/backups/${config.networking.hostName}"
      "ssh://eve/mnt/pool/backups/${config.networking.hostName}"
    ];
    "/mnt/pool" = ["ssh://pow/mnt/pool/backups/${config.networking.hostName}"];
  };

  # Send everything to backblaze
  services.backblaze = {
    enable = false;
    driveD = "/mnt/main/storage";
    driveE = "/mnt/data/storage";
    driveF = "/mnt/pool/storage";
  };

  # Services
  services.prometheus.enable = true;
  services.gitea.enable = true;
  services.jellyfin.enable = true;
  services.plex.enable = true;
  services.arr.enable = true;

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

  services.nfs.server = {
    enable = true;
    exports = "/media *(rw,fsid=1,insecure,no_subtree_check)";
  };
}
