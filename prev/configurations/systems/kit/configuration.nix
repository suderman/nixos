{
  config,
  pkgs,
  lib,
  hardware,
  profiles,
  ...
}: {
  # Import all *.nix files in this directory
  imports =
    lib.ls ./.
    ++ [
      hardware.rtx-4070-ti-super
      profiles.services # system services I use everywhere
      profiles.terminal # tui apps on all my workstations
      profiles.desktop # gui apps on all my workstations
      profiles.gaming # steam and emulation
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Sound & Bluetooth
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # Override DNS
  networking.extraHosts = ''
    18.191.53.91 www.parkwhiz.com
    127.0.0.1 example.com
    127.0.0.1 local
  '';

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
  };

  # Services
  services.garmin.enable = true;
}
