{ description = "Jon Suderman's NixOS configuration";

  inputs = {

    # Nix Packages 
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Nix User Repository
    # <https://nur.nix-community.org>
    nur.url = "github:nix-community/NUR";                                   

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager/release-23.05";
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
    agenix.inputs.home-manager.follows = "home-manager";

    # Home Manager Secrets
    # <https://github.com/jordanisaacs/homeage>
    homeage.url = "github:jordanisaacs/homeage";
    homeage.inputs.nixpkgs.follows = "nixpkgs";

    # Hyprland
    # <https://wiki.hyprland.org/Nix/Hyprland-on-NixOS>
    hyprland.url = "github:hyprwm/Hyprland";
    # hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    # hyprland-plugins.inputs.hyprland.follows = "hyprland";
    anyrun.url = "github:Kirottu/anyrun";
    # anyrun.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, ... }: 
    let inherit (self) outputs inputs; 

      # initialize this configuration with inputs and binary caches
      this = import ./. inputs [
        "https://suderman.cachix.org" "suderman.cachix.org-1:8lYeb2gOOVDPbUn1THnL5J3/L4tFWU30/uVPk7sCGmI="
        "https://nix-community.cachix.org" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "https://hyprland.cachix.org" "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "https://fufexan.cachix.org" "fufexan.cachix.org-1:LwCDjCJNJQf5XD2BV+yamQIMZfcKWR9ISIFy5curUsY="
        "https://nix-gaming.cachix.org" "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "https://anyrun.cachix.org" "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        "https://cache.nixos.org" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      # Get configured pkgs for a given system with overlays, nur and unstable baked in
      mkPkgs = this: import inputs.nixpkgs rec {
        system = this.system;

        # Accept agreements for unfree software
        config.allowUnfree = true;
        config.joypixels.acceptLicense = true;

        # Add to-be-updated packages blocking builds (none right now)
        config.permittedInsecurePackages = [ ];

        # Modify pkgs with this, sripts, packages, nur and unstable
        overlays = with this.lib; [ 

          # this and personal library
          (final: prev: { inherit this; })
          (final: prev: { this = import ./overlays/lib { inherit final prev; }; })

          # Personal scripts
          (final: prev: import ./overlays/bin { inherit final prev; } )
          (final: prev: pathToAttrs ./overlays/bin ( name: prev.callPackage ./overlays/bin/${name} {} ))

          # Additional packages
          (final: prev: import ./overlays/pkgs { inherit final prev; } )
          (final: prev: pathToAttrs ./overlays/pkgs ( name: prev.callPackage ./overlays/pkgs/${name} {} ))

          # Nix User Repositories 
          (final: prev: { nur = import inputs.nur { pkgs = final; nurpkgs = final; }; })

          # Unstable nixpkgs channel
          (final: prev: { unstable = import inputs.unstable { inherit system config; }; })

        ];

      };

      # Make a NixOS system configuration 
      mkConfiguration = this: inputs.nixpkgs.lib.nixosSystem rec {

        # Make nixpkgs for this system (with overlays)
        pkgs = mkPkgs this;
        system = pkgs.this.system;
        specialArgs = { inherit inputs outputs; this = pkgs.this; };

        # Include NixOS configurations, modules, secrets and caches
        modules = with pkgs.this; nixosModules ++ (if user == "root" then [] else [

          # Include Home Manager module (if user isn't "root")
          inputs.home-manager.nixosModules.home-manager { 
            home-manager = {

              # Inherit NixOS packages
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs outputs; this = pkgs.this; };

              # Include Home Manager configuration, modules, secrets and caches
              users."${user}" = let home = { imports }: { inherit imports; }; in home { 
                imports = homeModules; 
              };

            }; 
          } 

        ]);
      };

    # Flake outputs
    in {

      # NixOS configurations found in configurations directory
      nixosConfigurations = this.lib.pathToAttrs ./configurations (

        # Make configuration for each subdirectory 
        dir: mkConfiguration (this // import ./configurations/${dir} // { 
          nixosModules = this.nixosModules ++ [ ./configurations/${dir}/configuration.nix ];
          homeModules = this.homeModules ++ [ ./configurations/${dir}/home.nix ];
        })

      );

    };

}
