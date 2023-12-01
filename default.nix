# Attribute set of NixOS configurations found in each directory
{ inputs, caches ? [], ... }: let

  inherit (builtins) attrNames concatMap elem filter listToAttrs pathExists readDir;
  inherit (inputs.nixpkgs.lib) filterAttrs hasPrefix hasSuffix partition removeSuffix unique;
  inherit (lib) ls pathToAttrs;

  # Build cache module from list of pairs
  cacheModule = let 
    pair = (partition (value: (hasPrefix "https://" value)) caches);
    urls = pair.right; keys = pair.wrong; 
  in { ... }: {
    nix.settings.substituters = urls;  
    nix.settings.trusted-substituters = urls;  
    nix.settings.trusted-public-keys = keys;
  };

  # Import all modules and shared configuration
  nixosModules = 
    ls { path = ./configurations/bootstrap/nixos; filesExcept = []; } ++ 
    ls { path = ./modules; dirsWith = [ "default.nix" ]; } ++ 
    [ ./secrets cacheModule ];

  homeModules = 
    ls { path = ./configurations/bootstrap/home; filesExcept = []; } ++ 
    ls { path = ./modules; dirsWith = [ "home.nix" ]; } ++
    [ ./secrets cacheModule ];


  # Personal lib
  lib = {

    # List directories and files that can be imported by nix
    # ls { path = ./.; filesExcept = [ "flake.nix" ]; };
    # ls { path = ./modules; dirsWith = [ "default.nix" "home.nix" ]; filesExcept = []; };
    ls = let

      # Return list of directory names (with default.nix) inside path
      dirNames = path: dirsWith: full: let
        dirs = attrNames (filterAttrs (n: v: v == "directory") (readDir path));
        isVisible = (name: (!hasPrefix "." name));
        dirsWithFiles = (dirs: concatMap (dir: concatMap (file: ["${dir}/${file}"] ) dirsWith) dirs);
        isValid = dirFile: pathExists "${path}/${dirFile}";
        format = paths: map (dirFile: (if (full == true) then path + "/${dirFile}" else dirOf dirFile)) paths;
      in format (filter isValid (dirsWithFiles (filter isVisible dirs)));

      # Return list of filenames (ending in .nix) inside path 
      fileNames = path: filesExcept: full: let 
        files = attrNames (filterAttrs (n: v: v == "regular") (readDir path)); 
        isVisible = (name: (!hasPrefix "." name));
        isNix = (name: (hasSuffix ".nix" name));
        isAllowed = (name: !elem name filesExcept); 
        format = paths: map (file: (if (full == true) then path + "/${file}" else file)) paths;
      in format (filter isAllowed (filter isNix (filter isVisible files)));

    # Return list of directory/file names if full is false, otherwise list of absolute paths
    in { path, dirsWith ? [ "default.nix" ], filesExcept ? [ "default.nix" ], full ? true }: unique

      # No dirs if dirsWith is false, no files if filesExcept is false
      (if dirsWith == false then [] else (dirNames path dirsWith full)) ++
      (if filesExcept == false then [] else (fileNames path filesExcept full)); 


    # Create attribute set from files and subdirectories of path
    # pathToAttrs ./. ( name: { foo = "The directory or filename is ${name}"; } ); 
    pathToAttrs = path: fn: listToAttrs (
      map (filename: { 
        name = removeSuffix ".nix" filename;
        value = fn filename;
      }) (ls { inherit path; dirsWith = [ "default.nix" ]; filesExcept = [ "default.nix" ]; full = false; } )
    );

  };


in {

  # inputs + lib accessible from this
  inherit inputs lib;

  # NixOS and Home Manager modules imported in each configuration
  inherit nixosModules homeModules;

  # Default values, overridden in configuration/*/default.nix
  host = "nixos";  
  domain = "suderman.org"; 
  user = "me"; 
  system = "x86_64-linux";
  config = {};

}
