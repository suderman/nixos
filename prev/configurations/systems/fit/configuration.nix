{ config, lib, pkgs, hardware, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.radeon-rx-580
    profiles.services
    profiles.terminal
    profiles.desktop
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  programs.hyprland = {
    enable = true;
    autologin = "jon";
  };

  # Bigger banana
  stylix.cursor.size = 46;

}
