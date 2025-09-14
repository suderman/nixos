{flake, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Nix User Repositories
      nur = import flake.inputs.nur {
        pkgs = final;
        nurpkgs = final;
      };
    })
  ];
}
