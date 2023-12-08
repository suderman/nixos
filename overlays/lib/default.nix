# Personal helper library
{ final, prev, ... }: let 

  inherit (builtins) attrNames filter pathExists readDir;
  inherit (prev) callPackage lib stdenv this;
  inherit (lib) filterAttrs recursiveUpdate;
  inherit (this.lib) mkAttrs;

# Merge with existing this
in recursiveUpdate this { 

  # Import each lib/*.nix as a lib function
  lib = mkAttrs ./. ( module: import ./${module} { pkgs = prev; inherit lib this; } ) // rec {

    # Additional helper functions
    foo = "bar";

    # Home directory for user
    homeDir = user: "/${if (stdenv.isLinux) then "home" else "Users"}/${user}";

    # List of directory names
    dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

    # List of directory names containing default.nix
    moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

    # > config.users.users = this.lib.extraGroups this.users [ "mygroup" ] ;
    extraGroups = users: extraGroups: mkAttrs users (_: { inherit extraGroups; });

  };  

}
