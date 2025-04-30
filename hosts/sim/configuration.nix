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
    ];

    services.tailscale.enable = true;

    # Enable passwordless ssh access
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "yes";

      # Automatically remove stale sockets
      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      # Allow forwarding ports to everywhere
      settings.GatewayPorts = "clientspecified";

    };

  };
}
