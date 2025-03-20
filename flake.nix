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

    # https://github.com/numtide/blueprint/
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/numtide/devshell/
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = inputs: let flake = rec {

    flake = inputs.self;

    # map extra folders
    users = flake.lib.mkAttrs ./users ( user: import ./users/${user} );
    networks = {};
    secrets = ./secrets;

    agenix-rekey = inputs.agenix-rekey.configure {
      userFlake = flake;
      inherit (flake) nixosConfigurations;
    };

    # Derive Seeds (BIP-85) > 32-bytes hex > Index Number:
    derivationIndex = 1;

  # blueprint automatically maps: devshells, hosts, lib, modules, packages
  }; in inputs.blueprint { inherit inputs; } // flake;
}
