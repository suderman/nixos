{
  config,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.hardware.rtx-4070-ti-super
    flake.nixosModules.default
    flake.nixosModules.desktops.hyprland
    ./services.nix
    ./homelab.nix
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Always at home in my office
  networking.domain = "home";

  # Sound & Bluetooth
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
  };

  # Snapshots and backups
  services.btrbk.volumes = with config.networking; {
    "/mnt/main" = ["ssh://fit/mnt/pool/backups/${hostName}" "ssh://eve/mnt/pool/backups/${hostName}"];
    "/mnt/data" = ["ssh://fit/mnt/pool/backups/${hostName}"];
    "/mnt/game" = [];
  };
}
