# Personal helper library
{ final, prev, ... }: let 

  inherit (builtins) attrNames filter pathExists readDir stringLength;
  inherit (prev) callPackage lib stdenv this;
  inherit (lib) filterAttrs recursiveUpdate removePrefix removeSuffix;
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

    # Convert 3-digit mode (ie: 775) to 4-digit mode (ie: 0775) by padding a zero
    toMode = mode: let mode' = toString mode; in 
      if stringLength mode' == 3 then "0${mode'}" else mode'; 

    # Format owner and group as "owner:group"
    toOwnership = owner: group: "${toString owner}:${toString group}";

    # Trim newlines from beginning and end of string
    trim = text: removePrefix "\n" ( removeSuffix "\n" text );

  };  

}
