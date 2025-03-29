{ flake, config, lib, hostName, ... }: let
  inherit (builtins) readFile;
  inherit (lib) mkDefault mkOption types;
  inherit (flake.lib) trim;
in {

  # Extra options for each host
  options = {

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
      description = "NixOS SSH host public key";
      type = with types; nullOr str;
      default = null;
      example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKEb5HqzSaYjXrFkQ4MV5/80mcQCedPmE/sLiH2h6rI nixos@bip85-hex32-index1";
    };

  };

  config = {

    # Default to x86 linux
    nixpkgs.hostPlatform = mkDefault "x86_64-linux";

    # Set your time zone.
    time.timeZone = mkDefault "America/Edmonton";

    # Derive hostName from blueprint ./hosts/dir
    networking.hostName = hostName;

    # Set ssh host key and public key
    services.openssh = {
      privateKey = config.age.secrets.key.path or null; # custom option
      publicKey = trim( readFile( flake + /hosts/${hostName}/ssh_host_ed25519_key.pub )); # custom option
    };

    # Add host key to agenix 
    age.secrets.key = {
      rekeyFile = flake + /hosts/${hostName}/ssh_host_ed25519_key.age; 
    };

  };

}
