{ inputs, config, pkgs, lib, ... }: {

  # Import agenix module
  imports = [ inputs.agenix.nixosModules.default ];

  # Include agenix command
  config.environment.systemPackages = [
    inputs.agenix.packages."${pkgs.stdenv.system}".default
  ];

}
