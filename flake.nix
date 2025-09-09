{
  description = "playing with numtide blueprint for nixos";

  inputs = {
    # Nix Packages
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager/release-25.05"; # github:nix-community/home-manager
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # System-wide colorscheming & typography
    # <https://github.com/danth/stylix>
    stylix.url = "github:danth/stylix/release-25.05"; # github:danth/stylix
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    # Nix Index Database
    # <https://github.com/nix-community/nix-index-database>
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

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

    # NixOS secrets
    # <https://github.com/ryantm/agenix>
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    # <https://github.com/oddlama/agenix-rekey>
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning
    # <https://github.com/nix-community/disko>
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Map folder structure to flake outputs
    # <https://github.com/numtide/blueprint>
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    # Developer environments
    # <https://github.com/numtide/devshell>
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Nix User Repository
    # <https://nur.nix-community.org>
    nur.url = "github:nix-community/NUR";

    # Declarative flatpak manager
    # <https://github.com/gmodena/nix-flatpak>
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Quickshell
    # <https://quickshell.outfoxxed.me>
    quickshell.url = "github:quickshell-mirror/quickshell?ref=v0.2.0";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    # Neovim flake
    # <https://github.com/suderman/neovim>
    neovim.url = "github:suderman/neovim";

    # AI coding agents
    # <https://github.com/numtide/nix-ai-tools>
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
  };

  outputs = inputs: {
    # Blueprint automatically maps: devshells, hosts, lib, modules, packages
    inherit
      (inputs.blueprint {inherit inputs;})
      devShells
      packages
      formatter
      checks
      lib
      nixosConfigurations
      ;

    # Map additional folders to custom outputs
    inherit (inputs.self.lib) agenix-rekey networking users homeModules nixosModules;

    caches = [
      "suderman.cachix.org-1:8lYeb2gOOVDPbUn1THnL5J3/L4tFWU30/uVPk7sCGmI="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # Derive Seeds (BIP-85) > 32-bytes hex > Index Number:
    derivationIndex = 1;
  };
}
