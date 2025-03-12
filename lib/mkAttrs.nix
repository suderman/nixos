# Create attrs from list, attr names, or path
{ flake, lib, ... }: x: fn: let

  inherit (builtins) attrNames listToAttrs isAttrs isPath isList pathExists;
  inherit (lib) removeSuffix;
  inherit (flake.lib) ls;

  # Create attribute set from files and subdirectories of path
  fromPath = path: listToAttrs ( map 
    ( name: { name = (removeSuffix ".nix" name); value = (fn name); }) 
    ( ls { inherit path; asPath = false; dirsExcept = []; } )
  );

  # Create attribute set list of values
  fromList = list: listToAttrs ( map 
    ( name: { name = (removeSuffix ".nix" name); value = (fn name); }) 
    ( list ) 
  );

  # Do the same as above using the attrNames
  fromAttrs = attrs: fromList (attrNames attrs);

in 
  if (isPath x) then (fromPath x) 
  else if (isList x) then (fromList x)
  else if (isAttrs x) then (fromAttrs x)
  else {}
