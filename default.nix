# Attribute set of NixOS configurations found in each directory
{ inputs, caches ? [], ... }: let
  inherit (lib) ls mkAttrs mkList mkUsers;

  # Personal lib
  lib = {

    # List directories and files that can be imported by nix
    # ls { path = ./modules; dirsWith = [ "default.nix" "home.nix" ]; filesExcept = [ "default.nix" ]; };
    ls = let
      inherit (builtins) attrNames concatMap elem filter pathExists readDir;
      inherit (inputs.nixpkgs.lib) filterAttrs hasPrefix hasSuffix removeSuffix unique;

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
    in { path, dirsWith ? [ "default.nix" ], filesExcept ? [], full ? true }: unique

      # If path doesn't exist, return an empty list
      (if ! pathExists path then [] else 

        # If path is a nix file, return that path in a list
        (if hasSuffix ".nix" path then [ path ] else 

          # Assume path is a dir, no subdirs if dirsWith is false, no files if filesExcept is false
          (if dirsWith == false then [] else (dirNames path dirsWith full)) ++
          (if filesExcept == false then [] else (fileNames path filesExcept full))

        )
      );

    # Create list from path
    mkList = x: ( let 
      inherit (builtins) isPath pathExists;
      inherit (inputs.nixpkgs.lib) removeSuffix;

      # Create list from files and subdirectories of path
      fromPath = path: if ! pathExists path then [] else map 
        ( filename: removeSuffix ".nix" filename )
        ( ls { inherit path; full = false; } );

    in
      if (isPath x) then (fromPath x)
      else []
    );

    # Create attrs from list or path
    mkAttrs = x: fn: ( let 
      inherit (builtins) listToAttrs isPath isList pathExists;
      inherit (inputs.nixpkgs.lib) removeSuffix;

      # Create attribute set from files and subdirectories of path
      # fromPath = path: if ! pathExists path then {} else listToAttrs ( map 
      fromPath = path: listToAttrs ( map 
        (name: { name = (removeSuffix ".nix" name); value = (fn name); }) 
        (ls { inherit path; filesExcept = [ "default.nix" ]; full = false; } )
      );

      # Create list from files and subdirectories of path
      fromList = list: listToAttrs ( map 
        (name: { inherit name; value = (fn name); }) 
        (list) 
      );

    in
      if (isPath x) then (fromPath x) 
      else if (isList x) then (fromList x)
      else {}
    );

    # List of users for a particular nixos configuration
    mkUsers = host: mkList ./configurations/${host}/home;

    # List of users with a public key in the secrets directory
    mkAdmins = let 
      inherit (inputs.nixpkgs.lib) attrNames intersectLists remove; 
    in host: intersectLists ( mkUsers host ) (
      remove "all" ( attrNames (import ./secrets/keys).users )
    );

    # NixOS modules imported in each configuration
    mkModules = let 
      inherit (inputs.nixpkgs.lib) hasPrefix partition; 

      # Prepare cache module from list of pairs
      cacheModule = let 
        pair = (partition (value: (hasPrefix "https://" value)) caches);
        urls = pair.right; keys = pair.wrong; 
      in { ... }: {
        nix.settings.substituters = urls;  
        nix.settings.trusted-substituters = urls;  
        nix.settings.trusted-public-keys = keys;
      };

      # Include shared modules followed by dir-specific modules 
      in dir: 

      # Home Manager modules are organized under each user's name
      mkAttrs ./configurations/${dir}/home ( 
        home: 
          ls { path = ./configurations/all/home; } ++ # shared home-manager configuration
          ls { path = ./modules; dirsWith = [ "home.nix" ]; filesExcept = [ "default.nix" ]; } ++
          [ ./secrets cacheModule ] ++
          ls { path = ./configurations/${dir}/home/${home}; }

      # NixOS modules are organization under "root"
      ) // {
        root = 
          ls { path = ./configurations/all; } ++ # shared nixos configuration
          ls { path = ./modules; dirsWith = [ "default.nix" ]; filesExcept = [ "default.nix" ]; } ++ 
          [ ./secrets cacheModule ] ++
          [ ./configurations/${dir}/configuration.nix ];
      };

  };


in {

  # inputs + lib accessible from this
  inherit inputs lib;

  # Default values, overridden in configuration/*/default.nix
  host = "nixos";  
  domain = "suderman.org"; 

  users = []; # without users, only root exists
  admins = []; # allow sudo/ssh powers users with keys
  modules = {}; # includes for nixos and home-manager

  system = "x86_64-linux";
  config = {};

}
