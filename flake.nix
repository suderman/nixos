{
  description = "My personal NixOS configuration";

  inputs = {

    # Nix Packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # macOS Package Management
    darwin.url = "github:lnl7/nix-darwin/master";                              
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Nix User Repository
    nur.url = "github:nix-community/NUR";                                   

    # Save state
    impermanence.url = "github:nix-community/impermanence";

  };

  outputs = { self, ... }@inputs: 

    let 
      inherit (self) outputs;

      # Make a nixpkgs configuration
      mkPkgs = nixpkgs: system: import nixpkgs {
        inherit system;

        # Accept agreements for unfree software
        config.allowUnfree = true;
        config.joypixels.acceptLicense = true;

        # Include NIX User Repositories
        # https://nur.nix-community.org/
        config.packageOverrides = pkgs: {
          nur = import inputs.nur { pkgs = pkgs; nurpkgs = pkgs; };
        };
      };

      # Make a NixOS host configuration
      mkHost = hostname: system: inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = mkPkgs inputs.nixpkgs system;
        specialArgs = { inherit inputs outputs hostname; };
        modules = [ ./hosts/configuration.nix ];
      };

      # Make a Home Manager configuration
      mkHome = hostname: system: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs inputs.nixpkgs system;
        extraSpecialArgs = { inherit inputs outputs hostname; };
        modules = [ ./hosts/home.nix ];
      };

    in 
    rec {

      # My NixOS configurations
      nixosConfigurations = {
        cog    = mkHost "cog" "x86_64-linux";
        cog    = mkHost "cog" "x86_64-linux";
        lux    = mkHost "lux" "x86_64-linux";
        nimbus = mkHost "nimbus" "x86_64-linux";
      };

      # My Home Manager configurations
      homeConfigurations = {
        cog    = mkHome "cog" "x86_64-linux";
        lux    = mkHome "lux" "x86_64-linux";
        umbra  = mkHome "umbra" "x86_64-darwin";
        nimbus = mkHome "nimbus" "x86_64-linux";
      };

    };
}
