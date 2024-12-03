# services.flatpak.enable = true;
{ config, lib, pkgs, inputs, this, ... }:

let

  cfg = config.services.flatpak;
  inherit (lib) mkIf;

in {

  # https://github.com/gmodena/nix-flatpak/blob/main/modules/nixos.nix
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # options shared with home-manager module
  options.services.flatpak = import ./options.nix {
    inherit lib;  
    inherit (cfg) apps beta;
  };

  # config (mostly) shared with home-manager module
  config = mkIf cfg.enable {

    services.flatpak = import ./config.nix { 
      inherit lib;  
      inherit (cfg) apps beta all;
    } // {
      uninstallUnmanaged = false; # allow imperative system flatpaks
    }; 

    # portal required for flatpak
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # or xdg-desktop-portal-kde
    };

    # browse (and try) flatpaks via Gnome Software
    environment.systemPackages = with pkgs; [ gnome-software ];

  };


}
