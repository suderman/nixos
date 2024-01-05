# Personal helper library 
{ final, prev, ... }: let pkgs = prev;

  inherit (pkgs) lib;
  inherit (lib) recursiveUpdate;
  inherit (pkgs.this.lib) mkAttrs;

  # Merge with existing this
  this = recursiveUpdate pkgs.this { lib = let

    inherit (builtins) attrNames filter hasAttr pathExists readDir stringLength;
    inherit (lib) filterAttrs removePrefix removeSuffix;
    inherit (pkgs) this callPackage stdenv;

  # Additional helper functions this.lib.*
  in rec {

    # Home directory for user
    homeDir = user: "/${if (stdenv.isLinux) then "home" else "Users"}/${user}";

    # List of directory names
    dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

    # List of directory names containing default.nix
    moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

    # > config.users.users = this.lib.extraGroups this.users [ "mygroup" ] ;
    extraGroups = users: extraGroups: mkAttrs users (_: { inherit extraGroups; });

    # Convert 3-digit mode (ie: 775) to 4-digit mode (ie: 0775) by padding a zero
    toMode = mode: let mode' = toString mode; in if stringLength mode' == 3 then "0${mode'}" else mode'; 

    # Format owner and group as "owner:group"
    toOwnership = owner: group: "${toString owner}:${toString group}";

    # Trim newlines from beginning and end of string
    trim = text: removePrefix "\n" ( removeSuffix "\n" text );

    # Return pair of modules to import which disables the stable module and replaces it with unstable
    destabilize = input: path: [
      { disabledModules = [ path ]; } # first disable stable module
      ( if hasAttr "darwinModules" input 
        then "${input}/modules/${path}" # then add unstable home-manager module
        else "${input}/nixos/modules/${path}" # or add unstable nixos module
      ) 
    ];

  }; };

# Also import each lib/*.nix as a lib function
in recursiveUpdate this { 
  lib = mkAttrs ./. ( module: import ./${module} { inherit pkgs lib this; } );  
}
