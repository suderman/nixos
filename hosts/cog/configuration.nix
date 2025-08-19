{flake, ...}: {
  imports = [
    flake.nixosModules.common
    flake.nixosModules.extra
  ];
  networking.domain = "tail";
}
