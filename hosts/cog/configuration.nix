{
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.inputs.hardware.nixosModules.framework-11th-gen-intel
    flake.nixosModules.default
    flake.nixosModules.desktops.hyprland
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
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.mesa
      pkgs.vaapiVdpau
    ];
  };

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

  services.gitea.enable = true;
  services.grafana.enable = true;
  services.home-assistant = {
    enable = true;
    name = "hass";
    ip = flake.networking.zones.tail.cog;
  };
  services.jellyfin.enable = true;
  services.tandoor-recipes.enable = true;
}
