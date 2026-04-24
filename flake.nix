{
  description = "NixOS system configuration & dotfiles";

  inputs = {
    # Nix Packages
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager/release-25.11"; # github:nix-community/home-manager
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # System-wide colorscheming & typography
    # <https://github.com/danth/stylix>
    stylix.url = "github:danth/stylix/release-25.11"; # github:danth/stylix
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

    # Hyprland
    # <https://wiki.hypr.land/Nix/>
    hyprland.url = "github:hyprwm/Hyprland/v0.54.3";
    # <https://github.com/hyprwm/hyprland-plugins>
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";
    # <https://github.com/VirtCode/hypr-dynamic-cursors>
    hypr-dynamic-cursors.url = "github:VirtCode/hypr-dynamic-cursors/57e14edd0ae265b01828e466e287e96eb1e84dd3";
    hypr-dynamic-cursors.inputs.hyprland.follows = "hyprland";

    # Neovim flake
    # <https://github.com/suderman/neovim>
    neovim.url = "github:suderman/neovim";

    # AI coding agents
    # <https://github.com/numtide/llm-agents.nix>
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Hermes Agent
    # <https://github.com/NousResearch/hermes-agent>
    # TEMP: pinned to 520b8d9 (works) pending upstream fix for tui npmDepsHash regression in 6f1eed3
    hermes-agent.url = "github:NousResearch/hermes-agent/520b8d90020f0c952213be6fb65ec95da80d2105";
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;
    blueprint = inputs.blueprint {inherit inputs;};
    helperPackages = ["enableWayland" "mkApplication" "mkScript" "wrapWithFlags"];
    helperPackageChecks = map (name: "pkgs-${name}") helperPackages;
  in {
    # Blueprint automatically maps: devshells, hosts, lib, modules, packages
    inherit
      (blueprint)
      devShells
      formatter
      lib
      nixosConfigurations
      ;

    packages = lib.mapAttrs (_: packages: builtins.removeAttrs packages helperPackages) blueprint.packages;
    checks = lib.mapAttrs (_: checks: builtins.removeAttrs checks helperPackageChecks) blueprint.checks;

    # Map additional folders to custom outputs
    inherit
      (inputs.self.lib)
      agenix-rekey
      homeModules
      networking
      nixosModules
      users
      ;

    # Derive Seeds (BIP-85) > 32-bytes hex > Index Number:
    derivationIndex = 1;
  };
}
