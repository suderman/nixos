{
  pkgs,
  perSystem,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  # Allow disk override using disko cli, default to all disks
  # disko disk-configuration.nix --argstr disk ssd1 --mode destroy,format,mount
  _module.args.disk = "all";

  environment.systemPackages = [
    perSystem.disko.default
    pkgs.nixos-anywhere
  ];
}
