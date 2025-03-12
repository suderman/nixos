# Create list from path or list
{ flake, lib, ... }: x: let 

  inherit (builtins) isPath isList pathExists;
  inherit (lib) removeSuffix;
  inherit (flake.lib) ls;

  # Create list from files and subdirectories of path
  fromPath = path: if ! pathExists path then [] else map 
    ( filename: removeSuffix ".nix" filename )
    ( ls { inherit path; asPath = false; } );

  # Create list from list of values
  fromList = list: map 
    ( filename: removeSuffix ".nix" filename )
    ( list );

in
  if (isPath x) then (fromPath x)
  else if (isList x) then (fromList x)
  else []
