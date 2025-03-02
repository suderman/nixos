# Attribute set of NixOS configurations found in each directory
{ inputs, caches ? [], ... }: let
  inherit (lib) ls mkAttrs mkUsers mkList lsUsers nameFromPath;

  # Personal lib
  lib = {

    # List directories and files that can be imported by nix
    # ls ./modules;
    # ls { path = ./modules; dirsWith = [ "default.nix" "configuration.nix" ]; filesExcept = [ "default.nix" ]; asPath = true; };
    ls = x: ( let

      inherit (builtins) attrNames concatMap elem filter isAttrs isPath pathExists readDir;
      inherit (inputs.nixpkgs.lib) filterAttrs hasPrefix hasSuffix removeSuffix unique;

      # Return list of directory names (with default.nix) inside path
      dirNames = path: dirsWith: dirsExcept: asPath: let
        dirs = attrNames (filterAttrs (n: v: v == "directory") (readDir path)); 
        isAllowed = (name: !elem name dirsExcept); # default filters out dirs named "user"
        isVisible = (name: (!hasPrefix "." name));
        dirsWithFiles = (dirs: concatMap (dir: concatMap (file: ["${dir}/${file}"] ) dirsWith) dirs);
        isValid = dirFile: pathExists "${path}/${dirFile}";
        format = paths: map (dirFile: (if (asPath == true) then path + "/${dirFile}" else dirOf dirFile)) paths;
      in format (filter isValid (dirsWithFiles (filter isVisible (filter isAllowed dirs))));

      # Return list of filenames (ending in .nix) inside path 
      fileNames = path: filesExcept: asPath: let 
        files = attrNames (filterAttrs (n: v: v == "regular") (readDir path)); 
        isVisible = (name: (!hasPrefix "." name));
        isNix = (name: (hasSuffix ".nix" name));
        isAllowed = (name: !elem name filesExcept); 
        format = paths: map (file: (if (asPath == true) then path + "/${file}" else file)) paths;
      in format (filter isAllowed (filter isNix (filter isVisible files)));

      # Shortcut to pass path directly with default options
      fromPath = path: fromAttrs { inherit path; };

      # Return list of directory/file names if asPath is false, otherwise list of absolute paths
      fromAttrs = { path, dirsWith ? [ "default.nix" ], dirsExcept ? [ "user" ], filesExcept ? [ "flake.nix" "default.nix" "configuration.nix" "this.nix" ], asPath ? true }: unique
        (if ! pathExists path then [] else # If path doesn't exist, return an empty list
          (if hasSuffix ".nix" path then [ path ] else # If path is a nix file, return that path in a list
            (if dirsWith == false then [] else (dirNames path dirsWith dirsExcept asPath)) ++ # No subdirs if dirsWith is false, 
            (if filesExcept == false then [] else (fileNames path filesExcept asPath)) # No files if filesExcept is false
          )
        );

    in 
      if (isPath x) then (fromPath x)
      else if (isAttrs x) then (fromAttrs x)
      else []
    );

    # Create list from path or list
    mkList = x: ( let 
      inherit (builtins) isPath isList pathExists;
      inherit (inputs.nixpkgs.lib) removeSuffix;

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
    );

    # Create attrs from list, attr names, or path
    mkAttrs = x: fn: ( let 
      inherit (builtins) attrNames listToAttrs isAttrs isPath isList pathExists;
      inherit (inputs.nixpkgs.lib) removeSuffix;

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
    );

    # Like mkAttrs but only includes paths to configuration directories with this.nix
    mkConfigurations = fn: builtins.listToAttrs ( map 
      ( path: { name = nameFromPath path; value = (fn path); } )
      ( ls { path = ./configurations/systems; asPath = true; dirsWith = [ "this.nix" ]; dirsExcept = []; } )
    );

    # Like mkAttrs but only includes paths to user nix files or user directories
    mkUsers = hostName: fn: builtins.listToAttrs ( map
      ( path: { name = nameFromPath path; value = (fn path); } )
      ( ls { path = ./configurations/systems/${hostName}/users; asPath = true; dirsExcept = []; } )
    );  

    # List of users for a particular nixos configuration
    lsUsers = this: mkList( ls { 
      path = ./configurations/systems/${this.hostName}/users; asPath = false; dirsExcept = []; 
    });

    # List of users with a public key in the secrets directory
    lsAdmins = this: let 
      inherit (this.inputs.nixpkgs.lib) attrNames intersectLists remove; 
    in intersectLists ( lsUsers this ) (
      remove "all" ( attrNames (import ./secrets/keys).users )
    );

    # Determine name from file path
    nameFromPath = path: let
      inherit (builtins) toString;
      inherit (inputs.nixpkgs.lib) removeSuffix;
    in baseNameOf (removeSuffix ".nix" (removeSuffix "/this.nix" (removeSuffix "/configuration.nix" (removeSuffix "/default.nix" (removeSuffix "/user/default.nix" (toString path) )))));

    # Importable configuration profiles
    mkProfiles = this: let
      profilesFromPath = dirName: builtins.listToAttrs ( map 
        ( path: { name = nameFromPath path; value = (path); } )
        ( ls { path = ./configurations/profiles; asPath = true; dirsWith = [ "${dirName}/default.nix" ]; } )
      );
    in { root = profilesFromPath "/"; user = profilesFromPath "/user"; };

    # NixOS modules imported in each configuration
    mkModules = this: let 
      inherit (this) hostName;
      inherit (this.inputs) nix-index-database;
      inherit (this.inputs.nixpkgs.lib) hasPrefix mkDefault partition; 

      # Prepare cache module from list of pairs
      nix-cache = let 
        pair = (partition (value: (hasPrefix "https://" value)) caches);
        urls = pair.right; keys = pair.wrong; 
      in [( { ... }: {
        nix.settings.substituters = urls;  
        nix.settings.trusted-substituters = urls;  
        nix.settings.trusted-public-keys = keys;
      }) ];

      # Prepare nix-index module with weekly updated database and comma integration
      nix-index = let config = { ... }: { 
        programs.nix-index-database.comma.enable = mkDefault true; 
        programs.nix-index.enableBashIntegration = mkDefault false; 
        programs.nix-index.enableZshIntegration = mkDefault false; 
        programs.nix-index.enableFishIntegration = mkDefault false;
        programs.command-not-found.enable = mkDefault false;
      }; in {
        nixos = [ nix-index-database.nixosModules.nix-index config ];
        home = [ nix-index-database.hmModules.nix-index config ];
      };

      # Include shared modules followed by dir-specific modules 
      in
        # Home Manager modules are organized under each user's name
        mkUsers hostName (
          userPath: let userName = nameFromPath userPath; in 
            ls { path = ./modules; dirsWith = [ "user/default.nix" ]; } ++ # home-manager modules
            ls ./configurations/users/all/default.nix ++ # shared home-manager configuration for all users
            ls ./configurations/users/${userName}.nix ++ # shared home-manager configuration for one user
            ls ./configurations/users/${userName}/default.nix ++
            ls ./configurations/systems/${hostName}/users/${userName}.nix ++ # specific home-manager configuration for one user
            ls ./configurations/systems/${hostName}/users/${userName}/default.nix ++
            [ ./secrets ] ++ nix-cache ++ nix-index.home # secrets, keys, cache and index

        # NixOS modules are organization under "root"
        ) // {
          root = 
            ls { path = ./modules; dirsWith = [ "default.nix" ]; } ++ # nixos modules
            ls ./configurations/systems/all/configuration.nix ++ # shared nixos configuration for all systems
            ls ./configurations/systems/${hostName}/configuration.nix ++ # specific nixos configuration for one system
            [ ./secrets ] ++ nix-cache ++ nix-index.nixos # secrets, keys, cache and index
          ;
        };

  };

in {

  # inputs + lib accessible from this
  inherit inputs lib;

  # Default values, overridden in configuration/*/default.nix
  hostName = "nixos";  
  domain = ""; 

  users = []; # without users, only root exists
  admins = []; # allow sudo/ssh powers users with keys
  modules = {}; # includes for nixos and home-manager
  profiles = {}; # includes for nixos and home-manager

  system = "x86_64-linux";
  stable = true;
  config = {};

}
