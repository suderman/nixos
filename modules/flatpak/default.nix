# services.flatpak.enable = true;
{ config, lib, pkgs, inputs, ... }:

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
    xdg.portal.enable = true;

    # browse (and try) flatpaks via Gnome Software
    environment.systemPackages = [ pkgs.gnome.gnome-software ];

  };


}
