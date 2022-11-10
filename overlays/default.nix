{ inputs, system, config }: {

  # Auxiliary helper functions
  aux = final: prev: import ./aux { inherit inputs final prev; };

  # Override existing packages with modifications
  overrides = final: prev: import ./overrides { inherit inputs final prev; };

  # Personal packages
  pkgs = final: prev: import ./pkgs { inherit inputs; pkgs = final; };

  # NIX User Repositories 
  nur = final: prev: { nur = ( import inputs.nur { pkgs = final; nurpkgs = final; } ); };

  # Unstable nixpkgs channel with same system & config
  unstable = final: prev: { unstable = ( import inputs.unstable { inherit system config; } ); };

}
