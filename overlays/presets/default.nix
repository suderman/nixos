# Hardware and preset configurations
{ final, prev, ... }: let

  inherit (prev.lib) recursiveUpdate;
  inherit (prev.this) inputs;
  inherit (prev.this.lib) mkAttrs;

  # Merge existing this with presets from nixos hardware
  this = recursiveUpdate prev.this { 
    presets = inputs.hardware.nixosModules; 
  };

# Also merge with custom configs in this directory
in recursiveUpdate this {
  presets = mkAttrs ./. ( preset: import ./${preset} );
}
