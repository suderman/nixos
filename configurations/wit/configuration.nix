{ config, lib, pkgs, hardware, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.lenovo-thinkpad-t480s
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  programs.mosh.enable = true;
  programs.neovim.enable = true;

  # Web services
  services.tailscale.enable = true;
  services.whoami.enable = true;

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ness";

  # Agent to monitor system
  services.beszel.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGo/UVSuyrSmtE3RA0rxXpwApHEGMGOTd2c0EtGeCGAr";
}
