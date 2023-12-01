# Personal helper library
{ final, prev, ... }: let 

  inherit (builtins) attrNames filter pathExists readDir;
  inherit (prev) callPackage lib stdenv this;
  inherit (lib) filterAttrs recursiveUpdate;
  inherit (this.lib) pathToAttrs;

# Merge with existing this
in recursiveUpdate this { 

  # Import each lib/*.nix as a lib function
  lib = pathToAttrs ./. ( module: import ./${module} { pkgs = prev; inherit lib this; } ) // rec {

    # Additional helper functions
    foo = "bar";

    # Home directory for this user
    homeDir = "/${if (stdenv.isLinux) then "home" else "Users"}/${this.user}";

    # List of directory names
    dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

    # List of directory names containing default.nix
    moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

  };  

}
