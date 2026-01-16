{flake, ...}: {
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

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # CVE-2019-9501: heap buffer overflow
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.12.63"
    "broadcom-sta-6.30.223.271-59-6.12.65"
  ];

  # Bigger banana
  stylix.cursor.size = 46;

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [];
    "/mnt/pool" = [];
  };
}
