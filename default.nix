# Attribute set of NixOS configurations found in each directory
{ inputs, caches ? [], ... }: let

  inherit (builtins) attrNames concatMap elem filter listToAttrs pathExists readDir;
  inherit (inputs.nixpkgs.lib) filterAttrs hasPrefix hasSuffix intersectLists partition remove removeSuffix unique;
  inherit (lib) ls pathToAttrs;

  # Personal lib
  lib = {

    # List directories and files that can be imported by nix
    # ls { path = ./modules; dirsWith = [ "default.nix" "home.nix" ]; filesExcept = [ "default.nix" ]; };
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

    # Create attribute set from files and subdirectories of path
    # pathToAttrs ./. ( name: { foo = "The directory or filename is ${name}"; } ); 
    pathToAttrs = path: fn: if ! pathExists path then {} else listToAttrs (
      map (filename: { 
        name = removeSuffix ".nix" filename;
        value = fn filename;
      }) (ls { inherit path; full = false; } )
    );

    # Create list from files and subdirectories of path
    # pathToList ./. ( name: { foo = "The directory or filename is ${name}"; } ); 
    pathToList = path: if ! pathExists path then [] else map 
      ( filename: removeSuffix ".nix" filename )
      ( ls { inherit path; full = false; } );

    # Convert a list to an attribute set using a callback to generate the value
    # listToAttrs [ "foo" ] ( x: { name = "The name is ${x}"; } ); 
    # -> { foo = "The name is foo"; }
    listToAttrs = list: fn: listToAttrs ( 
      map (name: { inherit name; value = fn name; }) list 
    );

    # List of users for a particular nixos configuration
    mkUsers = host: lib.pathToList ./configurations/${host}/home;

    # List of users with a public key in the secrets directory
    mkAdmins = host: intersectLists ( lib.mkUsers host ) (
      remove "all" ( attrNames (import ./secrets/keys).users )
    );

    # NixOS modules imported in each configuration
    mkModules = let 

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
      pathToAttrs ./configurations/${dir}/home ( 
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
  admins = []; # allow sudo and ssh powers to these users (if they exist)

  system = "x86_64-linux";
  config = {};

}
