{ config, flake, pkgs, lib, perSystem, ... }: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
  inherit (perSystem.self) mkApplication;
in {

  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.common
    flake.nixosModules.vm
    flake.nixosModules.homelab
  ];

  config = {

    networking.domain = "tail";
    networking.firewall.allowPing = true;

    # Override encrypted/hashed password with this
    # users.users.jon.password = "x";

    environment.systemPackages = [
      pkgs.vim
      pkgs.yazi
      (mkApplication { 
        name = "yo"; 
        text = "echo yooooo";  
        desktopName = "Yo!";
        icon = flake + /prev/modules/zwift/user/zwift.svg;
        version = "2.0";
      })
      pkgs.fastfetch
      pkgs.cmatrix
      # pkgs.unstable.blocky
    ];

    services.tailscale.enable = true;
    services.traefik.enable = true;
    services.whoami.enable = true;
    services.blocky.enable = true;
    services.btrbk.enable = true;
    services.postgresql.enable = true;

    # App Store
    services.flatpak.enable = true;

    # Grant ssh host key access to root login
    users.users.root.openssh.authorizedKeys.keyFiles = [ 
      ./ssh_host_ed25519_key.pub 
    ];

    # Extra disks for motd
    programs.rust-motd.settings.filesystems = {
      data = "/mnt/data";
      pool = "/mnt/pool";
    };

    programs.firefox.enable = true;

    # Hub for monitoring other machines
    services.beszel.enable = true; # Agent to monitor system
    services.beszel.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGo/UVSuyrSmtE3RA0rxXpwApHEGMGOTd2c0EtGeCGAr";

  };
}
