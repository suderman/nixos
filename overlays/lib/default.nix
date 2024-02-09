# Personal helper library 
{ final, prev, ... }: let pkgs = prev;

  inherit (pkgs) lib;
  inherit (lib) recursiveUpdate;
  inherit (pkgs.this.lib) mkAttrs;

  # Merge with existing this
  this = recursiveUpdate pkgs.this { lib = let

    inherit (builtins) attrNames filter hasAttr hasSuffix isString pathExists readDir stringLength;
    inherit (lib) filterAttrs flatten removePrefix removeSuffix unique;
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
    destabilize = input: path: let 
      inherit (builtins) isList head tail toString;
      stablePath = toString( if (isList path) then (head path) else path ); 
      unstablePath = toString( if (isList path) then (tail path) else path ); 
    in [
      { disabledModules = [ stablePath ]; } # first disable stable module
      ( if hasAttr "darwinModules" input 
        then "${input}/modules/${unstablePath}" # then add unstable home-manager module
        else "${input}/nixos/modules/${unstablePath}" # or add unstable nixos module
      ) 
    ];

    # Set appId to package meta
    appId = appId: package: recursiveUpdate package { meta = { inherit appId; }; };

    # Get appId from pkg.meta, config.services.flatpak.packages, or appId string
    toAppId = pkg: 
      let appId = 
        if isString pkg && pkg != "" then "${pkg}.desktop" # flatpak str (append .desktop)
        else ( if hasAttr "appId" pkg && pkg.appId != "" then "${pkg.appId}.desktop" # flatpak attr (append .desktop)
        else if hasAttr "meta" pkg && hasAttr "appId" pkg.meta then pkg.meta.appId else "" ); # package with meta (as-is)
      in appId;

    # Unique list of appIds from list of packages
    appIds = list: let 
      appIds = filter (appId: appId != "") ( map (package: toAppId package) list );
    in unique appIds;

  }; };

# Also import each lib/*.nix as a lib function
in recursiveUpdate this { 
  lib = mkAttrs ./. ( module: import ./${module} { inherit pkgs lib this; } );  
}
