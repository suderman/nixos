{flake, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.default
  ];
  networking.domain = "home";
}
