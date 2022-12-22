{ inputs, config, ... }: {

  # Import homeage module
  imports = [ inputs.homeage.homeManagerModules.homeage ];

  # Configure homeage (agenix for home-manager)
  homeage.identityPaths = [ "~/.ssh/id_rsa" ];

}
