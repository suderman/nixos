{flake, ...}: {
  nixpkgs.overlays = [
    (final: _prev: {
      # Nix User Repositories
      nur = import flake.inputs.nur {
        pkgs = final;
        nurpkgs = final;
      };
    })
  ];
}
