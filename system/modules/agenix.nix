{ inputs, config, pkgs, ... }: {

  # Import agenix module
  imports = [ inputs.agenix.nixosModule ];

  # Include agenix command
  environment.systemPackages = [
    inputs.agenix.defaultPackage."${pkgs.stdenv.system}" 
  ];

}
