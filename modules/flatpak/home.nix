# -- modified module --
# services.flatpak.enable = true;
{ config, lib, inputs, ... }:

let

  cfg = config.services.flatpak;
  inherit (lib) mkIf;

in {

  # https://github.com/gmodena/nix-flatpak/blob/main/modules/home-manager.nix
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  # options shared with nixos module
  options.services.flatpak = import ./options.nix { 
    inherit lib;  
    inherit (cfg) apps beta;
  };

  # config (mostly) shared with nixos module
  config = mkIf cfg.enable {
    services.flatpak = import ./config.nix { 
      inherit lib;  
      inherit (cfg) apps beta all; 
    } // {
      uninstallUnmanaged = true; # manage user flatpaks declaratively
    }; 
  };

}
