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
    # anyrun.url = "github:Kirottu/anyrun";
    # anyrun.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, ... }: 
    
    with builtins;
    let inherit (self) outputs inputs; 

      # Additional binary caches and keys
      caches = { ... }: let 
        urls = [
          "https://suderman.cachix.org"
          "https://nix-community.cachix.org"
          "https://hyprland.cachix.org"
          "https://fufexan.cachix.org"
          "https://nix-gaming.cachix.org"
          "https://anyrun.cachix.org"
          "https://cache.nixos.org"
        ];
        keys = [
          "suderman.cachix.org-1:8lYeb2gOOVDPbUn1THnL5J3/L4tFWU30/uVPk7sCGmI="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "fufexan.cachix.org-1:LwCDjCJNJQf5XD2BV+yamQIMZfcKWR9ISIFy5curUsY="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
      in {
        nix.settings.substituters = urls;  
        nix.settings.trusted-substituters = urls;  
        nix.settings.trusted-public-keys = keys;
      };

      # Get configured pkgs for a given system with overlays, nur and unstable baked in
      mkPkgs = system: import inputs.nixpkgs rec {
        inherit system;

        # Accept agreements for unfree software
        config.allowUnfree = true;
        config.joypixels.acceptLicense = true;

        # Add to-be-updated packages blocking builds (none right now)
        config.permittedInsecurePackages = [ ];

        # Include personal scripts and package modifications
        overlays = with (import ./overlays { inherit inputs system config; } ); [ lib pkgs nur unstable ];

      };

      # Make a NixOS system configuration (with home-manager module, if user isn't "root")
      mkSystem = config: inputs.nixpkgs.lib.nixosSystem rec {
        specialArgs = { inherit inputs outputs; base = (import config); };
        inherit (specialArgs.base) system;
        pkgs = mkPkgs system;
        modules = [ 
          (config + /configuration.nix)
          ./modules/nixos 
          ./secrets 
          caches
        ] ++ (if specialArgs.base.user == "root" then [] else [
          inputs.home-manager.nixosModules.home-manager { 
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs outputs; base = (import config); };
              users."${specialArgs.base.user}" = let home = { imports }: { inherit imports; };
              in home { 
                imports = [
                  (config + /home.nix)
                  ./modules/home-manager 
                  ./secrets 
                  caches
                ]; 
              };
            }; 
          } 
        ]);
      };

      # Make a Home Manager configuration
      mkUser = config: inputs.home-manager.lib.homeManagerConfiguration rec {
        extraSpecialArgs = { inherit inputs outputs; base = (import config); };
        pkgs = mkPkgs extraSpecialArgs.system;
        modules = [ 
          (config + /home.nix)
          ./modules/home-manager 
          ./secrets 
          caches
        ];
      };

    in {

      # System configurations on NixOS
      nixosConfigurations = {

        # Bootstrap configuration
        bootstrap = mkSystem ./configurations/bootstrap;

        # Framework Laptop
        cog = mkSystem ./configurations/cog;

        # 2009 Mac Pro (at work)
        eve = mkSystem ./configurations/eve;

        # Intel NUC home server
        hub = mkSystem ./configurations/hub;

        # Intel NUC media server
        lux = mkSystem ./configurations/lux;

        # Mac Mini
        pom = mkSystem ./configurations/pom;

        # 2009 Mac Pro (at home)
        rig = mkSystem ./configurations/rig;

        # Linode VPS
        sol = mkSystem ./configurations/sol;

      };

      # Home configurations on other systems
      homeConfigurations = {
        # umbra = mkUser ./configurations/umbra; /* system = "x86_64-darwin" */
      };

    };

}
