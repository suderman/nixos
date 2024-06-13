# Hardware and preset configurations
{ final, prev, ... }: let

  inherit (prev.lib) recursiveUpdate;
  inherit (prev.this) inputs;
  inherit (prev.this.lib) mkAttrs;

# Merge presets from nixos hardware with custom configs in this directory
in recursiveUpdate inputs.hardware.nixosModules (
  mkAttrs ./. ( preset: import ./${preset} )
)
