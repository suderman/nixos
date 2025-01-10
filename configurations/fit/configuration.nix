{ config, lib, pkgs, hardware, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.common-gpu-amd
  ];

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_6_12; # lts

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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ libvdpau-va-gl vaapiVdpau ];
    extraPackages32 = with pkgs; [ libvdpau-va-gl vaapiVdpau ];
  };

}
