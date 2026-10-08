{
  config,
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

  # Single-profile capacity is intentional; separate-site copies provide redundancy.
  services.storage-health = {
    enable = true;
    volumes = {
      boot = {};
      main = {};
      pool = {
        # Allow the same mount time as Pow's similar two-HDD pool.
        mountTimeoutSec = 120;
        devices = [
          "${config.disko.devices.disk.hdd1.device}-part1"
          "${config.disko.devices.disk.hdd2.device}-part1"
        ];
      };
    };
  };

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = ["ssh://pow/mnt/pool/backups/${config.networking.hostName}"];
    "/mnt/pool" = [];
  };

  # Serve CA cert on http://10.2.0.2:1234
  services.traefik.caPort = 1234;

  services.ntfy-sh.enable = true;
}
