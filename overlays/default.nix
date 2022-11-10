{ inputs, system, config }: {

  # Personal scripts and packages
  additions = final: prev: import ./additions { inherit inputs; pkgs = final; };

  # Package modifications and helpers
  modifications = final: prev: import ./modifications { inherit inputs final prev; };

  # NIX User Repositories 
  nur = final: prev: { nur = ( import inputs.nur { pkgs = final; nurpkgs = final; } ); };

  # Unstable nixpkgs channel with same system & config
  unstable = final: prev: { unstable = ( import inputs.unstable { inherit system config; } ); };

}
