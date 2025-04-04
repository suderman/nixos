{ flake, inputs, ... }: let

  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = { inherit flake inputs lib; };

  inherit (builtins) attrNames attrValues filter head match pathExists readDir readFile stringLength;
  inherit (lib) filterAttrs removePrefix removeSuffix;

# Personal helper library 
in rec {

  # Extra flake outputs
  users = import ./users.nix args; 
  networks = mkAttrs ../networks (network: import ../networks/${network});
  agenix-rekey = inputs.agenix-rekey.configure {
    userFlake = flake;
    inherit (flake) nixosConfigurations;
  };

  # Bash script library
  bash = ./bash.sh;

  # List directories and files that can be imported by nix
  ls = import ./ls.nix args;

  # Create list from path or list
  mkList = import ./mkList.nix args; 

  # Create attrs from list, attr names, or path
  mkAttrs = import ./mkAttrs.nix args; 

  # Use systemd tmpfiles rules to create files, directories, symlinks and permissions changes
  mkRules = import ./mkRules.nix args; 

  # Create user attrs from path 
  mkUsers = import ./mkUsers.nix args; 

  # Flatten the network tree into a "hostName.domain = address" set
  mapping = import ./mapping.nix args; 

  # List of directory names
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # Given an attr set and a value, fetch the attr name with that value
  attrNameByValue = val: attr: toString ( attrNames (filterAttrs (n: v: v == val) attr) );

  # List of directory names containing default.nix
  moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

  # > config.users.users = this.lib.extraGroups this.users [ "mygroup" ] ;
  extraGroups = users: extraGroups: mkAttrs users (_: { inherit extraGroups; });

  # Convert 3-digit mode (ie: 775) to 4-digit mode (ie: 0775) by padding a zero
  toMode = mode: let mode' = toString mode; in if stringLength mode' == 3 then "0${mode'}" else mode'; 

  # Format owner and group as "owner:group"
  toOwnership = owner: group: "${toString owner}:${toString group}";

  # Trim whitespace from beginning and end of string
  trim = str: let m = match "[[:space:]]*(.*[^[:space:]])[[:space:]]*" str; in
    if m == null then
      if str == "" || match "[[:space:]]*" str != null
      then "" else str
    else
      head m;

  # readFile with whitespace trimmed
  trimFile = path: trim( readFile( path ) );

  # lib.derivationPath "salt"
  derivationPath = salt: let 
    prefix = if salt == "" then "" else "${salt}@"; 
  in prefix + "bip85-hex32-index${toString flake.derivationIndex}";

  # List of home-manager users that match provided filter function
  filterUsers = fn: cfg: filter fn (if cfg ? home-manager then attrValues cfg.home-manager.users else []);

}
