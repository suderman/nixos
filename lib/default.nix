{
  flake,
  inputs,
  ...
}: let
  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = {inherit flake inputs lib;};

  inherit
    (builtins)
    attrNames
    attrValues
    filter
    pathExists
    readDir
    ;
  inherit (lib) filterAttrs;
  # Personal helper library
in rec {
  # Extra flake outputs
  homeModules = import ./homeModules.nix args;
  nixosModules = import ./nixosModules.nix args;
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

  # Create attrs from list, attr names, or path
  genAttrs = import ./genAttrs.nix args;

  # List of directory names
  dirNames = path: attrNames (filterAttrs (_: v: v == "directory") (readDir path));

  # Given an attr set and a value, fetch the attr name with that value
  attrNameByValue = val: attr: toString (attrNames (filterAttrs (_: v: v == val) attr));

  # List of directory names containing default.nix
  moduleDirNames = path: filter (dir: pathExists "${path}/${dir}/default.nix") (dirNames path);

  # > config.users.users = flake.lib.extraGroups users [ "mygroup" ] ;
  extraGroups = cfg: extraGroups: let
    inherit (builtins) isList attrNames;
    userNames =
      if (isList cfg)
      then cfg
      else attrNames (cfg.home-manager.users or {});
  in
    genAttrs userNames (_: {
      inherit extraGroups;
    });

  # Filter only sudo users (in "wheel" group)
  sudoers = users:
    map (u: u.name) (builtins.attrValues (
      lib.filterAttrs (_: user: user ? extraGroups && builtins.elem "wheel" user.extraGroups) users
    ));

  # Filter only normal users (non-system users)
  normies = users:
    map (u: u.name) (builtins.attrValues (
      lib.filterAttrs (_: user: user.isNormalUser) users
    ));

  # List of home-manager users that match provided filter function
  filterUsers = cfg: fn:
    filter fn (
      if cfg ? home-manager
      then attrValues cfg.home-manager.users
      else []
    );

  # If this home-manager service is enabled for any user, set true
  homeService = cfg: name: let
    users = cfg.home-manager.users or {};
    inherit (builtins) attrNames any;
  in
    any (user: users.${user}.services.${name}.enable or false) (attrNames users);

  # If this home-manager program is enabled for any user, set true
  homeProgram = cfg: name: let
    users = cfg.home-manager.users or {};
    inherit (builtins) attrNames any;
  in
    any (user: users.${user}.programs.${name}.enable or false) (attrNames users);

  # Format owner and group as "owner:group"
  toOwnership = owner: group: "${toString owner}:${toString group}";

  # lib.derivationPath "salt"
  derivationPath = salt: let
    prefix =
      if salt == ""
      then ""
      else "${salt}@";
  in
    prefix + "bip85-hex32-index${toString flake.derivationIndex}";

  # Extract URL from cache public key
  cacheUrl = index: pubKey: let
    name = lib.pipe pubKey [
      (x: lib.split ":" x)
      (x: builtins.elemAt x 0)
      (x: lib.split "-" x)
      (x: lib.flatten x)
      (x: lib.take (builtins.length x - 1) x)
      (x: lib.concatStringsSep "-" x)
    ];
  in "https://${name}?priority=${toString index}";
}
