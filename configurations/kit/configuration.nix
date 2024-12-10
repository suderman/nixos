{ config, pkgs, lib, hardware, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.rtx-4070-ti-super
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Linux kernel (often have to manage this for nvidia compatibility)
  boot.kernelPackages = pkgs.linuxPackages_latest; # pkgs.linuxPackages_6_12;

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

  stylix = {
    enable = true;
    polarity = "dark";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";
    opacity.terminal = 0.85;
    cursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = 36;
    };
  };

}
