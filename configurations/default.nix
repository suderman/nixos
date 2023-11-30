# Attribute set of NixOS configurations found in each directory
this: with this.lib; let 

  # Import all modules and shared configuration
  nixosShared = ls { path = ./bootstrap/nixos; filesExcept = []; };
  nixosModules = ls { path = ../modules; };
  homeShared = ls { path = ./bootstrap/home; filesExcept = []; };
  homeModules = ls { path = ../modules; dirsWith = [ "home.nix" ]; };

in builtins.listToAttrs (
  map (directory: { 

    # Get name from host attribute or directory name
    name = (import ./${directory}).host or "${directory}";

    # Merge this with directory's default.nix
    value = this // import ./${directory} // {

      # Include all NixOS modules
      nixosModules = [
        ./${directory}/configuration.nix 
        ../secrets this.caches
      ] ++ nixosShared ++ nixosModules;

      # Include all Home Manager modules
      homeModules = [
        ./${directory}/home.nix
        ../secrets this.caches
      ] ++ homeShared ++ homeModules;

    };
  }) (ls { path = ./.; full = false; } )
)
