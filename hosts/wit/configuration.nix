{
  config,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.inputs.hardware.nixosModules.lenovo-thinkpad-t480s
    flake.nixosModules.default
    flake.nixosModules.desktops.gnome
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Mobile computing
  networking.domain = "tail";

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = ["ssh://fit/mnt/pool/backups/${config.networking.hostName}"];
  };
}
