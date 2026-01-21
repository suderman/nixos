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
    flake.nixosModules.desktop.gnome
  ];

  # Boot with good ol' grub
  boot.loader = {
    grub.enable = true;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true;
  };

  # Mobile computing
  networking.domain = "tail";

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [
      "ssh://pow/mnt/pool/backups/${config.networking.hostName}"
      "ssh://eve/mnt/pool/backups/${config.networking.hostName}"
    ];
  };
}
