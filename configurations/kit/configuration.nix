{ config, pkgs, lib, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    presets.rtx-4070-ti-super
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_10; # 6.11 broken

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
  services.tailscale = {
    enable = true;
    deleteRoute = "10.1.0.0/16";
  };

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
  };

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = false;
  programs.hyprland = {
    enable = true;
    autologin = "jon";
  };

  services.flatpak.enable = true;
  services.garmin.enable = true;

  # Apps
  programs.dolphin.enable = true;
  programs.steam.enable = true;
  programs.neovim.enable = true;
  programs.mosh.enable = true;

  # AirDrop alternative
  programs.localsend.enable = true; 
  networking.firewall = let port = 53317; in {
    allowedTCPPorts = [ port ];
    allowedUDPPorts = [ port ];
  };

  services.whoami.enable = true;
  modules.ollama.enable = true;
  services.ollama.acceleration = "cuda";

  networking.extraHosts = ''
    18.191.53.91 www.parkwhiz.com
    127.0.0.1 example.com
    127.0.0.1 local
  '';

}
