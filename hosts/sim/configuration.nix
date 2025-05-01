{ config, flake, pkgs, lib, ... }: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
in {

  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.common
    flake.nixosModules.vm
    flake.nixosModules.homelab
  ];

  config = {

    stable = false;
    
    networking.domain = "tail";
    networking.firewall.allowPing = true;

    # Override encrypted/hashed password with this
    # users.users.jon.password = "x";

    environment.systemPackages = [
      pkgs.vim
      pkgs.yazi
    ];

    services.tailscale.enable = true;

    # Grant ssh host key access to root login
    users.users.root.openssh.authorizedKeys.keyFiles = [ 
      ./ssh_host_ed25519_key.pub 
    ];

    # Extra disks for motd
    programs.rust-motd.settings.filesystems = {
      data = "/mnt/data";
      pool = "/mnt/pool";
    };

  };
}
