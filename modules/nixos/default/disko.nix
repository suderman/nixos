{
  pkgs,
  perSystem,
  flake,
  ...
}: {
  imports = [
    flake.inputs.disko.nixosModules.disko
  ];

  # Allow disk override using disko cli, default to all disks
  # disko disk-configuration.nix -m destroy,format,mount --arg disks '["ssd1"]'
  _module.args.disks = [];

  environment.systemPackages = [
    perSystem.disko.default
    pkgs.nixos-anywhere
  ];
}
