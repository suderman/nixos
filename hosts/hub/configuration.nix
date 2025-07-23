{ flake, ... }: {
  imports = [ flake.nixosModules.common ];
  config = { path = ./.; };
}
