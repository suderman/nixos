{ inputs, config, pkgs, lib, ... }: {

  # Import agenix module
  imports = [ inputs.agenix.nixosModule ];

  # # Host should have to opt into agenix secrets
  # options.age.enable = lib.options.mkEnableOption "age"; 

  # Include agenix command
  config.environment.systemPackages = [
    inputs.agenix.defaultPackage."${pkgs.stdenv.system}" 
  ];

}
