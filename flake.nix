{
  description = "My personal NixOS configuration";

  inputs = {

    # Nix Packages 
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Nix User Repository
    # <https://nur.nix-community.org>
    nur.url = "github:nix-community/NUR";                                   

    # Home manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS configuration
    # <https://daiderd.com/nix-darwin/manual>
    darwin.url = "github:lnl7/nix-darwin/master";                              
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS profiles for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:nixos/nixos-hardware";

    # Save state
    # <https://github.com/nix-community/impermanence>
    impermanence.url = "github:nix-community/impermanence";

    # Secrets
    # <https://github.com/ryantm/agenix>
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, ... }: 
    
    with builtins;
    let inherit (self) outputs inputs;

      # Get configured pkgs for a given system with overlays, nur and unstable baked in
      mkPkgs = system: import inputs.nixpkgs rec {
        inherit system;

        # Accept agreements for unfree software
        config.allowUnfree = true;
        config.joypixels.acceptLicense = true;

        # Include personal scripts and package modifications
        overlays = with (import ./overlays { inherit inputs system config; } ); [ pkgs nur unstable ];
      };

      # Make a NixOS host configuration
      mkHost = args@{ system ? "x86_64-linux", username ? "me", hostname, ... }: inputs.nixpkgs.lib.nixosSystem rec {
        inherit system;
        pkgs = mkPkgs system;
        specialArgs = args // { inherit inputs outputs username; };
        modules = [ inputs.agenix.nixosModule ./nixos/${hostname} ];
      };

      # Make a Home Manager configuration
      mkHome = args@{ system ? "x86_64-linux", username ? "me", ... }: inputs.home-manager.lib.homeManagerConfiguration rec {
        pkgs = mkPkgs system;
        extraSpecialArgs = args // { inherit inputs outputs username; };
        modules = [ ./home ];
      };

    in {

      # Framework Laptop
      nixosConfigurations.cog = mkHost { hostname = "cog"; };
      homeConfigurations.cog = mkHome {};

      # Linode VPS
      nixosConfigurations.nimbus = mkHost { hostname = "nimbus"; };
      homeConfigurations.nimbus = mkHome {};

      # Intel NUC home server
      nixosConfigurations.lux = mkHost { hostname = "lux"; };
      homeConfigurations.lux = mkHome {};

      # MacPro
      homeConfigurations.umbra = mkHome { system = "x86_64-darwin"; };

    };
}
