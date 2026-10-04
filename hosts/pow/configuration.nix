{
  config,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.hardware.radeon-rx-580
    flake.nixosModules.default
    flake.nixosModules.desktop.hyprland
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Always at home in my gym
  networking.domain = "home";

  # Keep local LAN traffic off Tailscale.
  services.tailscale.preferLocalRoute = "10.1.0.0/16";

  # Bigger banana
  stylix.cursor.size = 46;

  # Single-profile capacity is intentional; separate-site copies provide redundancy.
  services.storage-health = {
    enable = true;
    volumes = {
      boot = {};
      main = {};
      pool.devices = [
        "${config.disko.devices.disk.hdd1.device}-part1"
        "${config.disko.devices.disk.hdd2.device}-part1"
      ];
    };
  };

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = ["ssh://pow/eve/pool/backups/${config.networking.hostName}"];
    "/mnt/pool" = [];
  };
}
