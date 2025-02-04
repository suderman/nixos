{ config, lib, pkgs, ... }: let
  inherit (lib) mkDefault;
in {

  imports = [ 
    ./codecs.nix # media codecs
    ./fonts.nix # system-wide fonts
  ]; 

  # App Store
  services.flatpak.enable = true;

  # AirDrop alternative
  programs.localsend.enable = true; 

  # My color scheme
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";
    opacity.terminal = 0.85;
    cursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = mkDefault 36;
    };
  };

}
