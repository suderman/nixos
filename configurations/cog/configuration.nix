{ config, lib, pkgs, presets, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    presets.framework-11th-gen-intel
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Good graphics
  hardware.graphics.extraPackages = with pkgs; [
    mesa.drivers
    vaapiVdpau
  ];

  # Sound & Bluetooth
  services.pipewire.enable = true;
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;

  # framework_tool
  environment.systemPackages = with pkgs; [
    framework-tool
  ];

  # Network
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    127.0.0.1 example.com
    127.0.0.1 local
  '';

  # sudo fwupdmgr update
  services.fwupd.enable = true;

  # Lower fan noise 
  services.thermald.enable = true;

  # Power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.tlp.settings = {
    SATA_LINKPWR_ON_BAT = "max_performance";
    # CPU_BOOST_ON_BAT = 0;
    # CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
    # START_CHARGE_THRESH_BAT0 = 90;
    # STOP_CHARGE_THRESH_BAT0 = 97;
  };

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Memory management
  services.earlyoom.enable = true;

  # Keyboard control
  services.keyd = {
    enable = true;
    quirks = true;
    keyboard = config.services.keyd.internalKeyboards.framework;
  };

  services.flatpak.enable = true;
  services.garmin.enable = true;

  # Desktop environment
  services.xserver.desktopManager.gnome.enable = false;
  programs.hyprland.enable = true;

  # Web services
  services.traefik.enable = true;
  services.whoami.enable = true;

  # Apps & Games
  programs.neovim.enable = true;
  programs.steam.enable = true;
  programs.mosh.enable = true;
  programs.dolphin.enable = true;

}
