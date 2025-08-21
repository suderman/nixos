{flake, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.common
    flake.nixosModules.extra
  ];
  networking.domain = "home";
}
