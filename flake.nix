{
  description = "playing with numtide blueprint for nixos";

  inputs = {

    # https://github.com/NixOS/nixpkgs/
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/nix-community/impermanence
    impermanence.url = "github:nix-community/impermanence"; 

    # https://github.com/numtide/blueprint/
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/numtide/devshell/
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Nix Flake Registry
    # <https://github.com/nixos/flake-registry>
    flake-registry.url = "github:NixOS/flake-registry";
    flake-registry.flake = false;

  };

  outputs = inputs: let 

    # blueprint automatically maps: devshells, hosts, lib, modules, packages
    # blueprint = inputs.blueprint { inherit inputs; };  
    blueprint = builtins.removeAttrs
      ( inputs.blueprint { inherit inputs; } ) 
      [ "__functor" ];

    flake = {

      # map extra folders
      users = inputs.self.lib.mkUsers ./users;
      networks = {};

      agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = inputs.self;
        inherit (inputs.self) nixosConfigurations;
      };

      # Derive Seeds (BIP-85) > 32-bytes hex > Index Number:
      derivationIndex = 1;

    }; 

  in blueprint // flake;
}
