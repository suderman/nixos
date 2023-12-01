let
  flake = builtins.getFlake (toString ./.);
  default = import ./. { inherit (flake) inputs; };
  this = flake.nixosConfigurations.cog.pkgs.this;
in
{ inherit flake default this; }
// flake
// builtins
// flake.inputs.nixpkgs
// flake.inputs.nixpkgs.lib
// flake.nixosConfigurations
// this.lib
