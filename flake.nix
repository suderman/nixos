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

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS profiles for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:nixos/nixos-hardware";

    # Save state
    # <https://github.com/nix-community/impermanence>
    impermanence.url = "github:nix-community/impermanence";

    # NixOS Secrets
    # <https://github.com/ryantm/agenix>
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager Secrets
    # <https://github.com/jordanisaacs/homeage>
    homeage.url = "github:jordanisaacs/homeage";
    homeage.inputs.nixpkgs.follows = "nixpkgs";

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
        overlays = with (import ./overlays { inherit inputs system config; } ); [ lib pkgs nur unstable ];

      };

      # Make a NixOS system configuration (with home-manager module, if user isn't "root")
      mkSystem = args@{ system ? "x86_64-linux", user ? "root", domain ? "lan", host, ... }: inputs.nixpkgs.lib.nixosSystem rec {
        inherit system;
        pkgs = mkPkgs system;
        specialArgs = args // { inherit inputs outputs user host domain; };
        modules = [ 
          ./configurations/${host}/configuration.nix 
          ./modules/nixos 
          ./secrets 
        ] ++ (if user == "root" then [] else [
          inputs.home-manager.nixosModules.home-manager { 
            home-manager = {
              useGlobalPkgs = true; 
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs outputs user; };
              users."${user}" = let home = { imports }: { inherit imports; };
              in home { 
                imports = [
                  ./configurations/${host}/home.nix 
                  ./modules/home-manager 
                  ./secrets 
                ]; 
              };
            }; 
          } 
        ]);
      };

      # Make a Home Manager configuration
      mkUser = args@{ system ? "x86_64-linux", user, host, ... }: inputs.home-manager.lib.homeManagerConfiguration rec {
        pkgs = mkPkgs system;
        extraSpecialArgs = args // { inherit inputs outputs user; };
        modules = [ 
          ./configurations/${host}/home.nix 
          ./modules/home-manager 
          ./secrets 
        ];
      };

      user = "me";
      domain = "suderman.org";

    in {

      # System configurations on NixOS
      nixosConfigurations = {

        # Bootstrap configuration
        bootstrap = mkSystem { host = "bootstrap"; };

        # # Minimal system
        # min = mkSystem { host = "min"; inherit user; };

        # Framework Laptop
        cog = mkSystem { host = "cog"; inherit user domain; };

        # Intel NUC home server
        hub = mkSystem { host = "hub"; inherit user domain; };

        # Intel NUC media server
        lux = mkSystem { host = "lux"; inherit user domain; };

        # Linode VPS
        sol = mkSystem { host = "sol"; inherit user domain; };

      };

      # Home configurations on other systems
      homeConfigurations = {

        # 2009 MacPro
        umbra = mkUser { host = "umbra"; system = "x86_64-darwin"; inherit user; };

      };

    };

}
