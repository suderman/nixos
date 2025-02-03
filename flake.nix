{ description = "NixOS system configuration & dotfiles";

  inputs = {

    # Nix Packages 
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Unstable
    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # System-wide colorscheming & typography
    # <https://github.com/danth/stylix>
    stylix.url = "github:danth/stylix/release-24.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.home-manager.follows = "home-manager";
    # Unstable
    stylix-unstable.url = "github:danth/stylix";
    stylix-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    stylix-unstable.inputs.home-manager.follows = "home-manager-unstable";

    # Nix Index Database
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    # Unstable
    nix-index-database-unstable.url = "github:Mic92/nix-index-database";
    nix-index-database-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Nix Flake Registry
    # <https://github.com/nixos/flake-registry>
    flake-registry.url = "github:NixOS/flake-registry";
    flake-registry.flake = false;

    # NixOS profiles for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:NixOS/nixos-hardware";

    # Persist state
    # <https://github.com/nix-community/impermanence>
    impermanence.url = "github:nix-community/impermanence"; 

    # NixOS & Home Manager secrets
    # <https://github.com/ryantm/agenix>
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    # Unstable
    agenix-unstable.url = "github:ryantm/agenix";
    agenix-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    agenix-unstable.inputs.home-manager.follows = "home-manager-unstable";

    # Nix User Repository
    # <https://nur.nix-community.org>
    nur.url = "github:nix-community/NUR";                                   

    # Declarative flatpak manager
    # <https://github.com/gmodena/nix-flatpak>
    nix-flatpak.url = "github:gmodena/nix-flatpak"; 

  };

  outputs = { self, ... }: let 
    
    inherit (self) outputs inputs; 
    inherit (builtins) hasAttr elem mapAttrs length;
    inherit (inputs.nixpkgs.lib) getName; 
    inherit (this'.lib) lsAdmins lsUsers mkAttrs mkConfigurations mkModules mkProfiles;

    # Replace stable inputs with unstable (if available)
    unstableInputs = mapAttrs (k: v: if hasAttr "${k}-unstable" inputs then inputs."${k}-unstable" else v) inputs;

    # Initialize this configuration with inputs and binary caches
    this' = import ./this.nix { inherit inputs; caches = [
      "https://suderman.cachix.org" "suderman.cachix.org-1:8lYeb2gOOVDPbUn1THnL5J3/L4tFWU30/uVPk7sCGmI="
      "https://nix-community.cachix.org" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "https://hyprland.cachix.org" "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "https://fufexan.cachix.org" "fufexan.cachix.org-1:LwCDjCJNJQf5XD2BV+yamQIMZfcKWR9ISIFy5curUsY="
      "https://nix-gaming.cachix.org" "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "https://ai.cachix.org" "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
      "https://cache.nixos.org" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ]; };

    # Get configured pkgs for a given system with overlays, nur and unstable baked in
    mkPkgs = this: import this.inputs.nixpkgs rec {

      # System & other options is set in default.nix
      system = this.system;

      # Accept agreements for unfree software
      config.allowUnfree = true;
      config.allowUnfreePredicate = pkg: elem (getName pkg) [ "joypixels" ];
      config.joypixels.acceptLicense = true;
      config.nvidia.acceptLicense = true;

      # Add to-be-updated packages blocking builds
      config.permittedInsecurePackages = [
        "aspnetcore-runtime-wrapped-6.0.36"
        "aspnetcore-runtime-6.0.36"
        "dotnet-sdk-wrapped-6.0.428"
        "dotnet-sdk-6.0.428"
      ];

      # Modify pkgs with this, scripts, packages, nur and unstable
      overlays = [ 

        # this, and personal lib functions
        (final: prev: { inherit this; })
        (final: prev: { this = import ./overlays/lib { inherit final prev; }; })

        # Hardware configurations merged with nixos-hardware
        (final: prev: { hardware = import ./overlays/hardware { inherit final prev; }; })

        # Unstable/stable nixpkgs channel
        (final: prev: { unstable = import inputs.nixpkgs-unstable { inherit system config; }; })
        (final: prev: { stable = import inputs.nixpkgs { inherit system config; }; })

        # Nix User Repositories 
        (final: prev: { nur = import this.inputs.nur { pkgs = final; nurpkgs = final; }; })

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

    # NixOS/Home-Manager special args with merged lib from nixpkgs, home-manager, and this
    mkSpecialArgs = pkgs: context: {
      inherit outputs;
      inherit (pkgs.this) inputs;
      inherit (pkgs) this hardware;
      lib = pkgs.this.inputs.nixpkgs.lib.extend (_: _: pkgs.this.inputs.home-manager.lib // pkgs.this.lib );
      profiles = pkgs.this.profiles."${context}";
    };

    # Make a NixOS system configuration 
    mkConfiguration = this: this.inputs.nixpkgs.lib.nixosSystem rec {

      # Make nixpkgs for this system (with overlays)
      pkgs = mkPkgs this;
      system = pkgs.this.system;
      specialArgs = mkSpecialArgs pkgs "root";

      # Include NixOS configurations, modules, secrets and caches
      modules = this.modules.root ++ (if (length this.users < 1) then [] else [

        # Include Home Manager module (if there are any users besides root)
        this.inputs.home-manager.nixosModules.home-manager { 
          home-manager = {

            # Inherit NixOS packages
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = mkSpecialArgs pkgs "user";
            backupFileExtension = "bak"; # move existing config files out of the way

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
    nixosConfigurations = mkConfigurations (

      # Make configuration for each subdirectory 
      path: let
        this = import ./networks/this.nix ( this' // import path );
      in mkConfiguration ( this // { 
        users = lsUsers this;
        admins = lsAdmins this;
        modules = mkModules this;
        profiles = { root = mkProfiles "nixos"; user = mkProfiles "home"; };
        inputs = if this.stable then inputs else unstableInputs;
      })

    );

  };

}
