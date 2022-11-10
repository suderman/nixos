{
  description = "My personal NixOS configuration";

  inputs = {

    # Nix Packages 
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # change to nixos-22.11 when available
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
        overlays = with (import ./overlays { inherit inputs system config; } ); [ additions modifications nur unstable ];
      };

      # Defaults for host, determine user directory from system
      host = override: 
        let inherit ({ 
          system = "x86_64-linux"; # default system
          username = "me";         # default username
        } // override) system hostname username;
        in {
          inherit system hostname username; # inherit attributes and determine userdir from system 
          userdir = "/${if (toString (tail (split "-" system))) == "darwin" then "Users" else "home"}/${username}";
        };

      # Make a NixOS host configuration
      mkHost = host@{ system, hostname, username, ... }: inputs.nixpkgs.lib.nixosSystem {
        system = system;
        pkgs = mkPkgs system;
        specialArgs = { inherit inputs outputs host; };
        modules = [ ./hosts/${hostname}/configuration.nix 
          inputs.home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs outputs host; };
            home-manager.users.${username} = import ./hosts/${hostname}/home.nix;
          }
        ];
      };

      # Make a Home Manager configuration
      mkHome = host@{ system, hostname, ... }: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        extraSpecialArgs = { inherit inputs outputs host; };
        modules = [ ./hosts/${hostname}/home.nix ];
      };

    in {

      # My NixOS configurations
      nixosConfigurations = {
        cog    = mkHost (host { hostname = "cog"; });
        lux    = mkHost (host { hostname = "lux"; });
        nimbus = mkHost (host { hostname = "nimbus"; });
      };

      # My Home Manager configurations
      homeConfigurations = {
        cog    = mkHome (host { hostname = "cog"; });
        lux    = mkHome (host { hostname = "lux"; });
        nimbus = mkHome (host { hostname = "nimbus"; });
        umbra  = mkHome (host { hostname = "umbra"; system = "x86_64-darwin"; });
      };

    };
}
