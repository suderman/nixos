# modules.secrets.enable = true;
{ config, pkgs, lib, inputs, ... }:

let 

  cfg = config.modules.secrets;
  age = config.age;
  inherit (lib) mkIf mkOption types;
  inherit (lib.options) mkEnableOption;

in {

  # Import agenix module
  imports = [ inputs.agenix.nixosModules.default ];

  options.modules.secrets = {

    # Must opt into secrets
    enable = mkEnableOption "secrets"; 

    # Public keys
    keys = mkOption {
      type = types.attrs;
      description = "Import secrets/keys/default.nix";
      default = { users.all = []; systems.all = []; all = []; };
    };

    # Encrypted files
    files = mkOption {
      type = types.attrs;
      description = "Import secrets/files/default.nix";
      default = {};
    };

  };

  config = mkIf cfg.enable {

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

    # Loop through all encrypted files found in config.modules.secrets.files
    in builtins.listToAttrs ( 
      map secret (builtins.attrNames cfg.files)
    );
    
    # Secrets group
    ids.gids.secrets = 900;
    users.groups.secrets.gid = config.ids.gids.secrets;

  };

}
