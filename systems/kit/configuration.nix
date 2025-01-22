{ config, pkgs, lib, hardware, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.rtx-4070-ti-super
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Sound & Bluetooth
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd.enable = true;

  # Network
  networking.networkmanager.enable = true;
  services.whoami.enable = true;
  services.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };
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

  # Apps
  programs.neovim.enable = true;
  programs.mosh.enable = true;
  services.garmin.enable = true;

  # Agent to monitor system
  services.beszel.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGo/UVSuyrSmtE3RA0rxXpwApHEGMGOTd2c0EtGeCGAr";

}
