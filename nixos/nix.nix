{ config, inputs, lib, ... }: {

  nix.settings = {

    # Enable flakes and new 'nix' command
    experimental-features = [ "nix-command" "flakes" "repl-flake" ];

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    trusted-users = [ "root" "@wheel" ];
    warn-dirty = false;

    # substituters = [
    #   "https://hyprland.cachix.org"
    #   "https://nix-community.cachix.org"
    # ];
    # trusted-public-keys = [
    #   "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    #   "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    # ];

  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Add each flake input as a registry
  # To make nix3 commands consistent with the flake
  nix.registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

  # Map registries to channels
  # Very useful when using legacy commands
  nix.nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

}
