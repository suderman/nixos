# modules.secrets.enable = true;
{ config, lib, inputs, ... }: 

let 

  cfg = config.modules.secrets;
  inherit (lib) mkIf;

in {

  # Import homeage module
  imports = [ inputs.homeage.homeManagerModules.homeage ];

  config = mkIf cfg.enable {

    # Configure homeage (agenix for home-manager)
    homeage.identityPaths = [ "~/.ssh/id_rsa" ];

  };

}
