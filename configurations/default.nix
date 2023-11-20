# Attribute set of NixOS configurations found in each directory
inputs: let 

  inherit (builtins) attrNames listToAttrs map pathExists readDir;
  inherit (inputs.nixpkgs.lib) filterAttrs;

  # List all subdirectories in current directory
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # Null value for path that doesn't exist
  pathOrNull = path: if pathExists path then path else null;

in listToAttrs (
  map (directory: { 
    name = "${directory}"; 
    value = import ./${directory}/base.nix // {
      nixosConfig  = pathOrNull ./${directory}/configuration.nix;
      homeConfig   = pathOrNull ./${directory}/home.nix;
      nixosModules = pathOrNull ../modules;
      homeModules  = pathOrNull ../modules/home.nix;
      secrets      = pathOrNull ../secrets;
    };
  }) (dirNames ./.)
)
