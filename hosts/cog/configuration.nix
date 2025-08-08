{flake, ...}: {
  imports = [flake.nixosModules.common];
  config.networking.domain = "tail";
}
