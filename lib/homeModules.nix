{inputs, ...}: let
  pathAttrs = path:
    inputs.blueprint.lib.importDir path
    (inputs.nixpkgs.lib.mapAttrs (_name: {path, ...}: path));
in {
  default = ../modules/home/default;
  options = ../modules/home/options;
  profiles = pathAttrs ../modules/home/profiles;
  users = pathAttrs ../modules/home/users;
}
