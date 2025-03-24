{ config, lib, ... }: let

  cfg = config;
  inherit (lib) mkDefault mkIf mkOption types;
  inherit (builtins) baseNameOf pathExists;

in {

  # Extra options for each host
  options = {

    # Must be set in each configuration.nix: config.path = ./.;
    path = mkOption { 
      description = "Path to NixOS host configuration directory";
      type = types.path;
      default = /null;
      example = /etc/nixos/hosts/foo;
    };

    # Servers are stable, desktops can be unstable
    stable = mkOption {
      description = "Follow nixpkgs stable if true, unstable if false";
      type = types.bool;
      default = true;
      example = false;
    };

    # Extra networking option to track private ssh key
    networking.hostKey = mkOption { 
      description = "Path to (age-encrypted) NixOS SSH host private key";
      type = with types; nullOr path;
      default = null;
      example = /etc/nixos/hosts/foo/ssh_host_ed25519_key.age;
    };

    # Extra networking option to track public ssh key
    networking.hostPubkey = mkOption { 
      description = "Path to NixOS SSH host public key";
      type = with types; nullOr path;
      default = null;
      example = /etc/nixos/hosts/foo/ssh_host_ed25519_key.pub;
    };

  };

  config = mkIf (pathExists cfg.path) {

    # Default to x86 linux
    nixpkgs.hostPlatform = mkDefault "x86_64-linux";

    # Extra networking options
    networking = {

      # Derive hostName from configuration path
      hostName = baseNameOf cfg.path;

      # Set ssh host key if present
      hostKey = let 
        path = cfg.path + /ssh_host_ed25519_key.age;
      in if pathExists path then path else null;

      # Set ssh host public key if present
      hostPubkey = let 
        path = cfg.path + /ssh_host_ed25519_key.pub;
      in if pathExists path then path else null;

    };

    # Precious memories 
    system.stateVersion = "24.11";

  };

}
