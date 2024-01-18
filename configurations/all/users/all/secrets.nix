{ config, lib, inputs, ... }:

let 

  cfg = config.secrets;
  inherit (lib) mkIf mkOption types;

in {

  # Import homeage module
  imports = [ inputs.homeage.homeManagerModules.homeage ];

  # Extend homeage options
  options.homeage = {

    # Add age.enable option matching secrets.enable
    enable = mkOption { type = types.bool; default = cfg.enable; };

    # Add homeage.keys option matching secrets.keys
    keys = mkOption { type = types.anything; default = cfg.keys; };

  };

  config = mkIf cfg.enable {

    # Configure homeage (agenix for home-manager)
    homeage.identityPaths = [ "~/.ssh/id_ed25519" "~/.ssh/id_rsa" ];

  };

}
