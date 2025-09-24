{flake, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.hardware.radeon-rx-580
    flake.nixosModules.default
    flake.nixosModules.desktops.hyprland
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Always at home in my gum
  networking.domain = "home";

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # Bigger banana
  stylix.cursor.size = 46;

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [];
    "/mnt/pool" = [];
  };
}
