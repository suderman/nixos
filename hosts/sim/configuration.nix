{ config, flake, pkgs, lib, ... }: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
in {

  imports = [
    flake.nixosModules.common
    flake.nixosModules.vm
    flake.nixosModules.homelab
    ./storage.nix
  ];

  config = {

    stable = false;
    
    networking.domain = "tail";
    networking.firewall.allowPing = true;

    # Override encrypted/hashed password with this
    # users.users.jon.password = "x";

    environment.systemPackages = [
      pkgs.vim
    ];

    services.tailscale.enable = true;
    services.openssh.enable = true;

  };
}
