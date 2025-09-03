{
  config,
  pkgs,
  inputs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    inputs.hardware.nixosModules.framework-11th-gen-intel
    flake.nixosModules.common
    flake.nixosModules.extra
    flake.nixosModules.hyprland
  ];

  boot.loader = {
    grub.enable = true;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true;
  };

  networking.domain = "tail";

  # Use freshest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Good graphics
  hardware.graphics.extraPackages = [
    pkgs.mesa.drivers
    pkgs.vaapiVdpau
  ];

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = ["ssh://fit/mnt/pool/backups/${config.networking.hostName}"];
  };

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
