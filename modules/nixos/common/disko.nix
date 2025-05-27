{ pkgs, perSystem, inputs, ... }: {

  imports = [
    inputs.disko.nixosModules.disko
  ];

  config.environment.systemPackages = [ 
    perSystem.disko.default
    pkgs.nixos-anywhere
  ];

}
