{inputs, ...}: let
  pathAttrs = path:
    inputs.blueprint.lib.importDir path
    (inputs.nixpkgs.lib.mapAttrs (_name: {path, ...}: path));
in {
  default = ../modules/nixos/default;
  options = ../modules/nixos/options;
  overlays = ../modules/nixos/overlays;
  profiles = pathAttrs ../modules/nixos/profiles;
  hardware = pathAttrs ../modules/nixos/hardware;
  secrets = ../modules/nixos/secrets;
}
