{
  flake,
  inputs,
  ...
}: let
  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = {inherit flake inputs lib;};

  inherit (builtins) attrValues filter;
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

  # Inert identity-rotation state and selection policy
  identityRotationFor = import ./identityRotation.nix args;
  identityRotation = identityRotationFor (builtins.fromJSON (builtins.readFile ../secrets/rotation/state.json));

  # List directories and files that can be imported by nix
  ls = import ./ls.nix args;

  # Create attrs from list, attr names, or path
  genAttrs = import ./genAttrs.nix args;

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

  # List of home-manager users that match provided filter function
  filterUsers = cfg: pred: let
    users =
      if cfg ? home-manager
      then attrValues cfg.home-manager.users
      else [];
  in
    filter pred users;

  # Boolean if any use matches the above filter function
  anyUser = cfg: pred: (filterUsers cfg pred) != [];

  helperPackageNames = packages:
    builtins.attrNames (filterAttrs (_: package: package.meta.isHelper or false) packages);

  removeHelperPackages = packages:
    builtins.removeAttrs packages (helperPackageNames packages);

  removeHelperChecks = packages: checks:
    builtins.removeAttrs checks (map (name: "pkgs-${name}") (helperPackageNames packages));
}
