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
      mkHost = host: inputs.nixpkgs.lib.nixosSystem {
        system = host.system;
        pkgs = mkPkgs inputs.nixpkgs host.system;
        specialArgs = { inherit inputs outputs host; };
        modules = [ ./hosts/configuration.nix ];
      };

      # Make a Home Manager configuration
      mkHome = host: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs inputs.nixpkgs host.system;
        extraSpecialArgs = { inherit inputs outputs host; };
        modules = [ ./hosts/home.nix ];
      };

    in {

      # My NixOS configurations
      nixosConfigurations = {
        cog    = mkHost { username = "me"; hostname = "cog"; system = "x86_64-linux"; };
        lux    = mkHost { username = "me"; hostname = "lux"; system = "x86_64-linux"; };
        nimbus = mkHost { username = "me"; hostname = "nimbus"; system = "x86_64-linux"; };
      };

      # My Home Manager configurations
      homeConfigurations = {
        cog    = mkHome { username = "me"; hostname = "cog"; system = "x86_64-linux"; };
        lux    = mkHome { username = "me"; hostname = "lux"; system = "x86_64-linux"; };
        umbra  = mkHome { username = "me"; hostname = "umbra"; system = "x86_64-darwin"; };
        nimbus = mkHome { username = "me"; hostname = "nimbus"; system = "x86_64-linux"; };
      };

    };
}
