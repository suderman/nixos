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
  networking = import ./networking.nix args;
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

  # Create user attrs from path 
  mkUsers = import ./mkUsers.nix args; 

  # List of directory names
  dirNames = path: attrNames (filterAttrs (n: v: v == "directory") (readDir path));

  # Given an attr set and a value, fetch the attr name with that value
  attrNameByValue = val: attr: toString ( attrNames (filterAttrs (n: v: v == val) attr) );

  # List of directory names containing default.nix
  moduleDirNames = path: filter(dir: pathExists ("${path}/${dir}/default.nix")) (dirNames path);

  # > config.users.users = this.lib.extraGroups this.users [ "mygroup" ] ;
  extraGroups = users: extraGroups: mkAttrs users (_: { inherit extraGroups; });

  # Format owner and group as "owner:group"
  toOwnership = owner: group: "${toString owner}:${toString group}";

  # lib.derivationPath "salt"
  derivationPath = salt: let 
    prefix = if salt == "" then "" else "${salt}@"; 
  in prefix + "bip85-hex32-index${toString flake.derivationIndex}";

  # List of home-manager users that match provided filter function
  filterUsers = fn: cfg: filter fn (if cfg ? home-manager then attrValues cfg.home-manager.users else []);

  # Extract URL from cache public key
  cacheUrl = pubKey: let name = lib.pipe pubKey [
    (x: lib.split ":" x)
    (x: builtins.elemAt x 0)
    (x: lib.split "-" x)
    (x: lib.flatten x)
    (x: lib.take (builtins.length x - 1) x)
    (x: lib.concatStringsSep "-" x)
  ]; in "https://${name}";

}
