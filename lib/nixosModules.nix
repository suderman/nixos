{inputs, ...}: let
  pathAttrs = path:
    inputs.blueprint.lib.importDir path
    (inputs.nixpkgs.lib.mapAttrs (_name: {path, ...}: path));
in {
  default = ../modules/nixos/default;
  # Import only where needed; the upstream flake requires GitHub read access.
  boomboombaby = ../modules/nixos/boomboombaby.nix;
  desktop = pathAttrs ../modules/nixos/desktop;
  hardware = pathAttrs ../modules/nixos/hardware;
}
