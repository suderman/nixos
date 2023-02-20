# secrets.enable = true;
{ inputs, config, lib, ... }: 

let 
  cfg = config.secrets;

in {

  # Import homeage module
  imports = [ inputs.homeage.homeManagerModules.homeage ];

  config = lib.mkIf cfg.enable {

    # Configure homeage (agenix for home-manager)
    homeage.identityPaths = [ "~/.ssh/id_rsa" ];

  };

}
