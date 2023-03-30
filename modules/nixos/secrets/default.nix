# secrets.enable = true;
{ inputs, config, pkgs, lib, user, ... }:

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
        value = { 
          file = cfg.files."${key}"; 
          group = "secrets"; 
          mode = "440";
        }; 
      };

    # Loop through all encrypted files found in config.secrets.files
    in builtins.listToAttrs ( 
      map secret (builtins.attrNames cfg.files)
    );
    
    # Secrets group
    users.groups.secrets.gid = 1100;
    # users.users."${user}".extraGroups = [ "secrets" ]; 

  };

}
