{flake, ...}: {
  nixpkgs.overlays = [
    (_final: prev: {
      unstable = import flake.inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config = prev.config;
      };
    })
  ];
}
