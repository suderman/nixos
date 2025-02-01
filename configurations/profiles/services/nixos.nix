{ config, lib, ... }: let
  inherit (lib) mkDefault;
in {

  # Keyboard control
  services.keyd.enable = mkDefault true;

  # Network
  networking.networkmanager.enable = true;
  networking.extraHosts = mkDefault ''
    127.0.0.1 local
  '';

  # Enable VPN
  services.tailscale.enable = true;

  # Memory management
  services.earlyoom.enable = true;

  # Web services
  services.traefik.enable = true;
  services.whoami.enable = true;

  # Agent to monitor system
  services.beszel.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGo/UVSuyrSmtE3RA0rxXpwApHEGMGOTd2c0EtGeCGAr";

}
