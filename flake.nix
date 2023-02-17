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

      # Make a NixOS system configuration
      mkSystem = args@{ system ? "x86_64-linux", user ? "me", domain ? "lan", publicDomain ? "", host, ... }: inputs.nixpkgs.lib.nixosSystem rec {
        inherit system;
        pkgs = mkPkgs system;
        specialArgs = args // { inherit inputs outputs user host domain publicDomain; };
        modules = [ 
          ./hosts/${host}/configuration.nix 
          inputs.home-manager.nixosModules.home-manager { home-manager = {
            useGlobalPkgs = true; useUserPackages = true;
            extraSpecialArgs = { inherit inputs outputs user; };
            users."${user}" = import ./hosts/${host}/home.nix;
          }; } 
        ];

      };

      # Make a Home Manager configuration
      mkUser = args@{ system ? "x86_64-linux", user? "me", host, ... }: inputs.home-manager.lib.homeManagerConfiguration rec {
        pkgs = mkPkgs system;
        extraSpecialArgs = args // { inherit inputs outputs user; };
        modules = [ ./hosts/${host}/home.nix ];
      };

      domain = "suderman.org";
      publicDomain = "suderman.net";

    in {

      # System configurations on NixOS
      nixosConfigurations = {

        # Bootstrap
        bootstrap = mkSystem { host = "bootstrap"; };

        # Framework Laptop
        cog = mkSystem { host = "cog"; inherit domain; };

        # Linode VPS
        sol = mkSystem { host = "sol"; inherit domain publicDomain; };

        # Intel NUC home server
        lux = mkSystem { host = "lux"; inherit domain publicDomain; };

      };

      # Home configurations on other systems
      homeConfigurations = {

        # MacPro
        umbra = mkUser { host = "umbra"; system = "x86_64-darwin"; };

      };

    };
}
