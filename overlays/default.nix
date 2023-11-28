{ inputs, config, this }: {

  # Personal library, packages and overrides
  pkgs = self: super: import ./pkgs { inherit inputs self super; this' = this; };

  # NIX User Repositories 
  nur = self: super: { nur = ( import inputs.nur { pkgs = self; nurpkgs = self; } ); };

  # Unstable nixpkgs channel with same system & config
  unstable = self: super: { unstable = ( import inputs.unstable { inherit config; system = this.system; } ); };

}
