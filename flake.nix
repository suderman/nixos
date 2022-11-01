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

  };

  outputs = inputs: 

    let 

      # Make a nixpkgs configuration
      # mkPkgs = nixpkgs: system: import nixpkgs {
      #   inherit system;
      #   config.allowUnfree = true;
      #   config.joypixels.acceptLicense = true;
      # };
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

      # mkPkgs = nixpkgs: system: 
      #   let 
      #     pkgs = import nixpkgs {
      #       inherit system;
      #       config.allowUnfree = true;
      #       config.joypixels.acceptLicense = true;
      #       config.packageOverrides = pkgs: {
      #         nur = import nur { 
      #           pkgs = pkgs;
      #           nurpkgs = pkgs; 
      #         };
      #       };
      #     };  
      #     nurpkgs = pkgs;
      #     pkgs.config.packageOverrides = pkgs: {
      #       nur = import nur { inherit pkgs nurpkgs; };
      #     };
      #   in pkgs;

      # in nixpkgs: system: import nixpkgs {
      #   inherit system;
      #   config.allowUnfree = true;
      #   config.joypixels.acceptLicense = true;
      #   overlays = [(final: prev: { 
      #     nur = import inputs.nur {
      #
      #     }
      #     nur = inputs.nur { inherit system; };
      #   })];
      # };

      # Make a NixOS host configuration
      mkHost = hostname: system: inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = mkPkgs inputs.nixpkgs system;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/${hostname}/configuration.nix ];
      };

      # Make a Home Manager configuration
      mkHome = system: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs inputs.nixpkgs system;
        modules = [ ./home.nix ];
      };

    in 
    {

      # My NixOS configurations - look in the hosts directory for more
      nixosConfigurations = {
        nimbus = mkHost "nimbus" "x86_64-linux";
        cog = mkHost "cog" "x86_64-linux";
        lux = mkHost "lux" "x86_64-linux";
      };

      # My Home Manager configuraiton - look in home.nix for more
      homeConfigurations = {
        me = mkHome "x86_64-linux";
      };

    };
}
