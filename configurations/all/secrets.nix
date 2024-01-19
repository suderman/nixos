{ config, lib, pkgs, this, inputs, ... }:

let 

  cfg = config.secrets;
  age = config.age;
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) mkAttrs;

in {

  # Import agenix module
  imports = [ inputs.agenix.nixosModules.default ];

  # Extend age options
  options.age = {

    # Add age.enable option matching secrets.enable
    enable = mkOption { type = types.bool; default = cfg.enable; };

    # Add age.keys option matching secrets.keys
    keys = mkOption { type = types.anything; default = cfg.keys; };

  };

  config = mkIf cfg.enable {

    # agenix command
    environment.systemPackages = [
      inputs.agenix.packages."${pkgs.stdenv.system}".default
    ];

    # Set agenix secrets
    age.secrets = mkAttrs cfg.files (key: {
      file = cfg.files."${key}"; 
      group = "secrets"; 
      mode = "440";
    });
    
    # Secrets group
    ids.gids.secrets = 900;
    users.groups.secrets.gid = config.ids.gids.secrets;

  };

}
