# secrets.enable = true;
{ inputs, config, pkgs, lib, ... }:

let 
  cfg = config.secrets;
  age = config.age;

in {

  # Import agenix module
  imports = [ inputs.agenix.nixosModules.default ];

  config = lib.mkIf cfg.enable {

    # agenix command
    environment.systemPackages = [
      inputs.agenix.packages."${pkgs.stdenv.system}".default
    ];

    # Set agenix secrets
    age.secrets = let 

      # Example: age.secrets.password.file = cfg.files.password;
      secret = key: { 
        name = "${key}"; 
        value = { file = cfg.files."${key}"; }; 
      };

    # Loop through all encrypted files found in config.secrets.files
    in builtins.listToAttrs ( 
      map secret (builtins.attrNames cfg.files)
    );
    
  };

}
