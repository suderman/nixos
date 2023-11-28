# Attribute set of NixOS configurations found in each directory
inputs: caches: let 

  inherit (builtins) attrNames listToAttrs map readDir;
  inherit (inputs.nixpkgs.lib) filterAttrs;

  # List all subdirectories in current directory
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

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
