{ inputs, system, config }: {

  # Personal lib functions
  lib = self: super: { lib = super.lib // ( import ./lib { inherit inputs self super; } ); };

  # Personal packages and overrides
  pkgs = self: super: import ./pkgs { inherit inputs self super; };

  # NIX User Repositories 
  nur = self: super: { nur = ( import inputs.nur { pkgs = self; nurpkgs = self; } ); };

  # Unstable nixpkgs channel with same system & config
  unstable = self: super: { unstable = ( import inputs.unstable { inherit system config; } ); };

}
