{ lib, flake, ... }: {

  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;

  # Default enable these common modules for all hosts
  programs.neovim.enable = lib.mkDefault true;
  programs.rust-motd.enable = lib.mkDefault true;
  services.blocky.enable = lib.mkDefault true;
  services.btrbk.enable = lib.mkDefault true;
  services.earlyoom.enable = lib.mkDefault true;
  services.keyd.enable = lib.mkDefault true;
  services.tailscale.enable = lib.mkDefault true;
  services.traefik.enable = lib.mkDefault true;
  services.whoami.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;
  virtualisation.docker.enable = lib.mkDefault true;

  # Precious memories 
  system.stateVersion = "24.11";

}
