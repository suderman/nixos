{ config, lib, pkgs, hardware, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.radeon-rx-580
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Apps
  services.whoami.enable = true;
  programs.neovim.enable = true;
  programs.mosh.enable = true;
  programs.dolphin.enable = true;
  programs.steam.enable = true;

  # AirDrop alternative
  programs.localsend.enable = true; 

  # Web services
  services.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = false;
  programs.hyprland = {
    enable = true;
    autologin = "jon";
  };

  # Agent to monitor system
  services.beszel.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGo/UVSuyrSmtE3RA0rxXpwApHEGMGOTd2c0EtGeCGAr";

  # Snapshots & backup with btrbk
  # This also allows other computers to send their backups here
  services.btrbk.enable = true;

}
