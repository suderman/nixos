{
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.hardware.framework-11th-gen-intel
    flake.nixosModules.default
    flake.nixosModules.desktop.hyprland
  ];

  # Boot with good ol' grub
  boot.loader = {
    grub.enable = true;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true;
  };

  # Mobile computing
  networking.domain = "tail";

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
    "/mnt/main" = ["ssh://eve/mnt/pool/backups/${config.networking.hostName}"];
  };

  # Power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
  services.tlp.settings.SATA_LINKPWR_ON_BAT = "max_performance";
  services.thermald.enable = true; # Lower fan noise

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Experiments
  services.gitea.enable = false;
  services.grafana.enable = false;
  services.home-assistant = {
    enable = false;
    name = "hass";
    ip = flake.networking.zones.tail.cog;
  };
  services.jellyfin.enable = false;
  services.tandoor-recipes.enable = false;
  services.whoogle.enable = false;
  services.tiddlywiki.enable = true;

  # Garmin fenix 6 pro
  hardware.garmin.deviceId = "091e:4cda";
}
