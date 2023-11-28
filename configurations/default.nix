# Attribute set of NixOS configurations found in each directory
inputs: caches: let 

  inherit (builtins) attrNames listToAttrs map pathExists readDir;
  inherit (inputs.nixpkgs.lib) filterAttrs;

  # List all subdirectories in current directory
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # Null value for path that doesn't exist
  pathOrNull = path: if pathExists path then path else null;

in listToAttrs (
  map (directory: { 
    name = (import ./${directory}).host or "${directory}";
    value = import ./${directory} // {
      nixosModules = [
        ./bootstrap/nixos
        ./${directory}/configuration.nix
        ../modules
        ../secrets
        caches
      ];
      homeModules = [
        ./bootstrap/home
        ./${directory}/home.nix
        ../modules/home.nix
        ../secrets
        caches
      ];
    };
  }) (dirNames ./.)
)
