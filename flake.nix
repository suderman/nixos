{ description = "NixOS system configuration & dotfiles";

  inputs = {

    # Nix Packages 
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";

    # Nix Index Database
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS profiles for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:NixOS/nixos-hardware";

    # Persist state
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

    # Nix User Repository
    # <https://nur.nix-community.org>
    nur.url = "github:nix-community/NUR";                                   

    # Declarative flatpak manager
    # <https://github.com/gmodena/nix-flatpak>
    nix-flatpak.url = "github:gmodena/nix-flatpak"; 

    # Hyprland
    # <https://github.com/hyprwm/Hyprland/releases>
    hyprland.url = "github:hyprwm/Hyprland/v0.35.0";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    anyrun.url = "github:Kirottu/anyrun";

  };

  outputs = { self, ... }: let 
    
    inherit (self) outputs inputs; 
    inherit (builtins) length;
    inherit (this.lib) mkAttrs mkUsers mkAdmins mkModules;

    # Initialize this configuration with inputs and binary caches
    this = import ./. { inherit inputs; caches = [
      "https://suderman.cachix.org" "suderman.cachix.org-1:8lYeb2gOOVDPbUn1THnL5J3/L4tFWU30/uVPk7sCGmI="
      "https://nix-community.cachix.org" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "https://hyprland.cachix.org" "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "https://fufexan.cachix.org" "fufexan.cachix.org-1:LwCDjCJNJQf5XD2BV+yamQIMZfcKWR9ISIFy5curUsY="
      "https://nix-gaming.cachix.org" "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "https://anyrun.cachix.org" "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      "https://cache.nixos.org" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ]; };

    # Get configured pkgs for a given system with overlays, nur and unstable baked in
    mkPkgs = this: import inputs.nixpkgs rec {

      # System & other options is set in default.nix
      system = this.system;

      # Accept agreements for unfree software
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
      config.joypixels.acceptLicense = true;

      # Add to-be-updated packages blocking builds (none right now)
      config.permittedInsecurePackages = [];

      # Modify pkgs with this, scripts, packages, nur and unstable
      overlays = [ 

        # this and personal lib functions
        (final: prev: { inherit this; })
        (final: prev: { this = import ./overlays/lib { inherit final prev; }; })

        # Unstable nixpkgs channel
        (final: prev: { unstable = import inputs.nixpkgs-unstable { inherit system config; }; })

        # Nix User Repositories 
        (final: prev: { nur = import inputs.nur { pkgs = final; nurpkgs = final; }; })

        # Package overrides
        (final: prev: mkAttrs ./overlays/mods ( name: import ./overlays/mods/${name} { inherit final prev; } ))
        (final: prev: import ./overlays/mods { inherit final prev; } )

        # Additional packages
        (final: prev: mkAttrs ./overlays/pkgs ( name: prev.callPackage ./overlays/pkgs/${name} {} ))
        (final: prev: import ./overlays/pkgs { inherit final prev; } )

        # Personal scripts
        (final: prev: mkAttrs ./overlays/bin ( name: prev.callPackage ./overlays/bin/${name} {} ))
        (final: prev: import ./overlays/bin { inherit final prev; } )

      ];

    };

    # Make a NixOS system configuration 
    mkConfiguration = this: inputs.nixpkgs.lib.nixosSystem rec {

      # Make nixpkgs for this system (with overlays)
      pkgs = mkPkgs this;
      system = pkgs.this.system;
      specialArgs = { inherit inputs outputs; this = pkgs.this; };

      # Include NixOS configurations, modules, secrets and caches
      modules = this.modules.root ++ (if (length this.users < 1) then [] else [

        # Include Home Manager module (if there are any users besides root)
        inputs.home-manager.nixosModules.home-manager { 
          home-manager = {

            # Inherit NixOS packages
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs outputs; this = pkgs.this; };

            # Include Home Manager configuration, modules, secrets and caches
            users = mkAttrs this.users ( 
              user: ( ({ imports }: { inherit imports; }) { 
                imports = this.modules."${user}";
              } )
            ); 

          }; 
        } 

      ]);
    };

  # Flake outputs
  in {

    # NixOS configurations found in configurations directory
    nixosConfigurations = mkAttrs ./configurations (

      # Make configuration for each subdirectory 
      hostName: mkConfiguration ( import ./networks (this // import ./configurations/${hostName} ) // { 
        users = mkUsers hostName;
        admins = mkAdmins hostName;
        modules = mkModules hostName;
      })

    );

  };

}
