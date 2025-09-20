{
  config,
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkIf mapAttrs;
  inherit (builtins) toString;
in {
  # Nix Settings
  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = ["nix-command" "flakes" "pipe-operators"];
    # experimental-features = [ "nix-command" "flakes" "repl-flake" ];

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    # Root and sudo users
    trusted-users = ["root" "@wheel"];

    # Supress annoying warning
    warn-dirty = false;

    # https://discourse.nixos.org/t/how-to-prevent-flake-from-downloading-registry-at-every-flake-command/32003/3
    flake-registry = "${inputs.flake-registry}/flake-registry.json";

    # Speed up remote builds
    builders-use-substitutes = true;
  };

  nix.sshServe = {
    enable = true;
    keys = config.secrets.keys.all;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Add each flake input as a registry
  # To make nix3 commands consistent with the flake
  nix.registry = mapAttrs (_: value: {flake = value;}) inputs;

  # Map registries to channels
  # Very useful when using legacy commands
  nix.nixPath = let path = toString ./.; in ["repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}"];

  # Automatically upgrade this system while I sleep
  system.autoUpgrade = {
    enable = false;
    dates = "04:00";
    flake = "/etc/nixos#${config.networking.hostName}";
    flags = [
      "--update-input"
      "nixpkgs"
      "--update-input"
      "unstable"
      "--update-input"
      "nur"
      "--update-input"
      "home-manager"
      "--update-input"
      "agenix"
      "--update-input"
      "impermanence"
      # "--commit-lock-file"
    ];
    allowReboot = true;
  };
}
