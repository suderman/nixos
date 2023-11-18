# Import all Home Manager modules
{ lib, ... }: let 

  # Modules are named "home.nix"
  file = "home.nix";

  inherit (builtins) attrNames filter map pathExists readDir;
  inherit (lib) filterAttrs;

  # List all directories in current directory
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # List modules in each subdirectory
  modules = filter (path: pathExists path) (map (dir: ./${dir}/${file}) (dirNames ./.));

in { imports = modules; }
