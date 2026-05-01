{
  config,
  lib,
  flake,
  ...
}: {
  # Nix Settings
  nix.settings = {
    # Enable flakes and pipes
    experimental-features = ["nix-command" "flakes" "pipe-operators"];

    # 500MB buffer
    download-buffer-size = 500000000;

    # https://bmcgee.ie/posts/2023/12/til-how-to-optimise-substitutions-in-nix/
    http-connections = 128;
    max-substitution-jobs = 128;

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
  nix.registry = lib.mapAttrs (_: value: {flake = value;}) flake.inputs;

  # Map registries to channels
  nix.nixPath = ["repl=${flake}/repl.nix" "nixpkgs=${flake.inputs.nixpkgs}"];

  # Automatically upgrade this system while I sleep
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    dates = "04:00";
    randomizedDelaySec = "45min";
    flake = "github:suderman/nixos#${config.networking.hostName}";
    flags = ["--refresh"];
    allowReboot = lib.mkDefault true;
  };

  # Failing to build manual right now
  documentation.nixos.enable = false;
}
