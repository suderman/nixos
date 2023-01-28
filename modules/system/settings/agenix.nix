{ inputs, config, pkgs, lib, ... }: {

  # Import agenix module
  imports = [ inputs.agenix.nixosModule ];

  # Include agenix command
  config.environment.systemPackages = [
    inputs.agenix.defaultPackage."${pkgs.stdenv.system}" 
  ];

}
