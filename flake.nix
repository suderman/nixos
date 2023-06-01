{ description = "Jon Suderman's NixOS configuration";

  inputs = {

    # Nix Packages 
    # <https://search.nixos.org/packages>
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
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

    # Home Manager Secrets
    # <https://github.com/jordanisaacs/homeage>
    homeage.url = "github:jordanisaacs/homeage";
    homeage.inputs.nixpkgs.follows = "nixpkgs";

    # Hyperland
    # <https://wiki.hyprland.org/Nix/Hyprland-on-NixOS>
    hyprland.url = "github:hyprwm/Hyprland";
    # hyprland.inputs.nixpkgs.follows = "nixpkgs";

    anyrun.url = "github:Kirottu/anyrun";
    anyrun.inputs.nixpkgs.follows = "nixpkgs";

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

        # OpenSSL 1.1 is reaching its end of life on 2023/09/11 and cannot be supported through the NixOS 23.05 release cycle.
        # https://www.openssl.org/blog/blog/2023/03/28/1.1.1-EOL/ 
        config.permittedInsecurePackages = [ "openssl-1.1.1u" ];

        # Include personal scripts and package modifications
        overlays = with (import ./overlays { inherit inputs system config; } ); [ lib pkgs nur unstable ] ++ [
          inputs.anyrun.overlay 
        ];

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

      # My username
      user = "me"; 

      # My private network
      domain = "suderman.org";

    in {

      # System configurations on NixOS
      nixosConfigurations = {

        # Bootstrap configuration
        bootstrap = mkSystem { host = "bootstrap"; };

        # Framework Laptop
        cog = mkSystem { host = "cog"; inherit user domain; };

        # Intel NUC home server
        hub = mkSystem { host = "hub"; inherit user domain; };

        # Intel NUC media server
        lux = mkSystem { host = "lux"; inherit user domain; };

        # Linode VPS
        sol = mkSystem { host = "sol"; inherit user domain; };

        # Mac Mini
        pom = mkSystem { host = "pom"; inherit user domain; };

        # 2009 Mac Pro (at work)
        eve = mkSystem { host = "eve"; inherit user domain; };

      };

      # # Home configurations on other systems
      # homeConfigurations = {
      #
      #   # 2009 MacPro
      #   umbra = mkUser { host = "umbra"; system = "x86_64-darwin"; inherit user; };
      #
      # };

    };

}
