{
  config,
  lib,
  flake,
  ...
}: let
  inherit (builtins) attrNames attrValues;
  inherit (lib) mapAttrs imap1;
in {
  # Nix Settings
  nix.settings = {
    # Enable flakes and pipes
    experimental-features = ["nix-command" "flakes" "pipe-operators"];

    # 500MB buffer
    download-buffer-size = 500000000;

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    # Root and sudo users
    trusted-users = ["root" "@wheel"];

    # Supress annoying warning
    warn-dirty = false;

    # https://discourse.nixos.org/t/how-to-prevent-flake-from-downloading-registry-at-every-flake-command/32003/3
    flake-registry = "${flake.inputs.flake-registry}/flake-registry.json";

    # Speed up remote builds
    builders-use-substitutes = true;

    # Binary caches
    substituters = imap1 (i: url: "${url}?priority=${toString i}") (attrNames flake.caches);
    trusted-public-keys = attrValues flake.caches;
  };

  nix.sshServe = {
    enable = true;
    keys = let
      userKeys = flake.lib.ls {
        path = flake + /users;
        dirsWith = ["id_ed25519.pub"];
      };
    in
      map (key: builtins.readFile key) userKeys;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Add each flake input as a registry
  # To make nix3 commands consistent with the flake
  nix.registry = mapAttrs (_: value: {flake = value;}) flake.inputs;

  # Map registries to channels
  nix.nixPath = ["repl=${flake}/repl.nix" "nixpkgs=${flake.inputs.nixpkgs}"];

  # Automatically upgrade this system while I sleep
  system.autoUpgrade = {
    enable = false;
    dates = "04:00";
    flake = "/etc/nixos#${config.networking.hostName}";
    flags = [
      # "--update-input" "nixpkgs"
      # "--update-input" "unstable"
      # "--update-input" "nur"
      # "--update-input" "home-manager"
      # "--update-input" "agenix"
      # "--update-input" "impermanence"
      # "--commit-lock-file"
    ];
    allowReboot = true;
  };

  # Failing to build manual right now
  documentation.nixos.enable = false;
}
