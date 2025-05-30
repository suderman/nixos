{ config, flake, ... }: {

  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;

  # App Store
  services.flatpak.enable = true;

  # AirDrop alternative
  programs.localsend.enable = true; 

}
