# Extend nixpkgs' genAttrs to first convert provided paths or attrs to a list
{ lib, flake, ... }: x: fn: let

  # Ensure string and strip .nix suffix from any entries
  fromList = list: map (name: lib.removeSuffix ".nix" (toString name)) list;

  # List of directory and filenames in given path
  fromPath = path: fromList ( flake.lib.ls { 
    inherit path; asPath = false; dirsExcept = []; 
  });

  # List of attribute names in given attr set
  fromAttrs = attrs: fromList (builtins.attrNames attrs);

  inherit (builtins) isAttrs isPath isList;
  list = if (isPath x) then (fromPath x)
    else if (isList x) then (fromList x)
    else if (isAttrs x) then (fromAttrs x)
    else [];

# Pass along modified list and provided function to nixpkgs's genAttrs
in lib.genAttrs list fn
