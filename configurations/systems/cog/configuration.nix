{ config, lib, pkgs, hardware, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    hardware.framework-11th-gen-intel
    profiles.services # system services I use everywhere
    profiles.terminal # tui apps on all my workstations
    profiles.desktop # gui apps on all my workstations
    profiles.gaming # steam and emulation
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

  # Laptop-specific
  services.fwupd.enable = true; # sudo fwupdmgr update
  services.thermald.enable = true; # Lower fan noise 

  # Power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.tlp.settings.SATA_LINKPWR_ON_BAT = "max_performance";

  # Override DNS
  networking.extraHosts = ''
    # 159.203.49.164 touchstoneexploration.com www.touchstoneexploration.com
    # 159.203.49.164 paramountres.com www.paramountres.com 
    18.191.53.91 www.parkwhiz.com
    127.0.0.1 example.com
    127.0.0.1 local
  '';

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Keyboard control
  services.keyd = {
    enable = true;
    quirks = true;
    keyboard = config.services.keyd.internalKeyboards.framework;
  };

}
