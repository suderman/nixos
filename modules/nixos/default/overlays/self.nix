{perSystem, ...}: {
  nixpkgs.overlays = [
    (_final: _prev: {
      inherit (perSystem) self;
    })
  ];
}
