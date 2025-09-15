{inputs, ...}: let
  pathAttrs = path:
    inputs.blueprint.lib.importDir path
    (inputs.nixpkgs.lib.mapAttrs (_name: {path, ...}: path));
in {
  default = ../modules/nixos/default;
  desktops = pathAttrs ../modules/nixos/desktops;
  hardware = pathAttrs ../modules/nixos/hardware;
  overlays = ../modules/nixos/overlays;
  secrets = ../modules/nixos/secrets;
}
