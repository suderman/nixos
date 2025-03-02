{ config, lib, pkgs, hardware, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.lenovo-thinkpad-t480s
    profiles.services
    profiles.terminal
    profiles.desktop
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keyboard control
  services.keyd.enable = false;

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ness";

}
