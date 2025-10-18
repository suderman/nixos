{inputs, ...}: let
  pathAttrs = path:
    inputs.blueprint.lib.importDir path
    (inputs.nixpkgs.lib.mapAttrs (_name: {path, ...}: path));
in {
  default = ../modules/home/default;
  desktop = pathAttrs ../modules/home/desktop;
  users = pathAttrs ../modules/home/users;
}
