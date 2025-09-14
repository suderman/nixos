{perSystem, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      unstable = perSystem.nixpkgs-unstable;
    })
  ];
}
