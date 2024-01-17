# modules.flatpak.enable = true;
{ config, lib, inputs, ... }:

let

  cfg = config.modules.flatpak;
  inherit (lib) mkIf;

in {

  # https://github.com/gmodena/nix-flatpak/blob/main/modules/home-manager.nix
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  # options shared with nixos module
  options.modules.flatpak = import ./options.nix { 
    inherit lib;  
    inherit (cfg) packages betaPackages;
  };

  # config (mostly) shared with nixos module
  config = mkIf cfg.enable {
    services.flatpak = import ./config.nix { 
      inherit lib;  
      inherit (cfg) packages betaPackages; 
    }; 
  };

}
