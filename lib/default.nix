{ flake, inputs, ... }: let

  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = { inherit flake inputs lib; };

  inherit (builtins) attrNames attrValues filter pathExists readDir stringLength;
  inherit (lib) filterAttrs removePrefix removeSuffix;

# Personal helper library 
in rec {

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

  # Trim newlines from beginning and end of string
  trim = text: removePrefix "\n" ( removeSuffix "\n" text );

  # List of home-manager users that match provided filter function
  filterUsers = fn: cfg: filter fn (if cfg ? home-manager then attrValues cfg.home-manager.users else []);

}
