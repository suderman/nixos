{ flake, config, lib, ... }: let

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
      example = ./hosts/foo;
    };

    # Servers are stable, desktops can be unstable
    stable = mkOption {
      description = "Follow nixpkgs stable if true, unstable if false";
      type = types.bool;
      default = true;
      example = false;
    };

    # Extra networking option for private ssh key
    services.openssh.privateKey = mkOption { 
      description = "Path to NixOS SSH host private key";
      type = with types; nullOr path;
      default = null;
      example = /run/agenix/foo-key;
    };

    # Extra networking option for public ssh key
    services.openssh.publicKey = mkOption { 
      description = "Path to NixOS SSH host public key";
      type = with types; nullOr path;
      default = null;
      example = ./hosts/foo/ssh_host_ed25519_key.pub;
    };

  };

  config = mkIf (pathExists cfg.path) {

    # Derive hostName from configuration path
    networking.hostName = baseNameOf cfg.path;

    # Set ssh host key and public key
    services.openssh = {
      privateKey = config.age.secrets.key.path or null; # custom option
      publicKey = cfg.path + /ssh_host_ed25519_key.pub; # custom option
    };

    # Add host key to agenix 
    age.secrets.key = with cfg.networking; {
      rekeyFile = flake + /hosts/${hostName}/ssh_host_ed25519_key.age; 
    };

  };

}
