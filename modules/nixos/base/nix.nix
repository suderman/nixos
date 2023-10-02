{ config, lib, inputs, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf mapAttrs;
  inherit (builtins) toString;

in {

  config = mkIf cfg.enable {

    # Nix Settings
    nix.settings = {

      # Enable flakes and new 'nix' command
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];

      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      # Root and sudo users
      trusted-users = [ "root" "@wheel" ];

      # Supress annoying warning
      warn-dirty = false;

      builders-use-substitutes = true;

    };


    # Automatic garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Add each flake input as a registry
    # To make nix3 commands consistent with the flake
    nix.registry = mapAttrs (_: value: { flake = value; }) inputs;

    # Map registries to channels
    # Very useful when using legacy commands
    # nix.nixPath = mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    nix.nixPath = let path = toString ./.; in [ "repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}" ];

    # Automatically upgrade this system while I sleep
    system.autoUpgrade = {
      enable = false;
      dates = "04:00";
      flake = "/etc/nixos#${config.networking.hostName}";
      flags = [ 
        "--update-input" "nixpkgs"
        "--update-input" "unstable"
        "--update-input" "nur"
        "--update-input" "home-manager"
        "--update-input" "agenix"
        "--update-input" "impermanence"
        # "--commit-lock-file" 
      ];
      allowReboot = true;
    };

  };

}
