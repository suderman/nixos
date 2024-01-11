# modules.flatpak.enable = true;
{ config, lib, pkgs, this, inputs, ... }:

let

  cfg = config.modules.flatpak;
  inherit (lib) mkIf mkOption types;
  inherit (lib.options) mkEnableOption;

in {

  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  options.modules.flatpak = {
    enable = mkEnableOption "flatpak"; 
    packages = mkOption { type = with types; (listOf str); default = []; }; 
    betaPackages = mkOption { type = with types; (listOf str); default = []; }; 
  };

  config = mkIf cfg.enable {

    services.flatpak = {
      enable = true;
      update.auto.enable = true;
      remotes = [
        { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
        { name = "flathub-beta"; location = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo"; }
      ];
      packages = (
        map ( appId: { inherit appId; origin = "flathub"; } ) cfg.packages
      ) ++ (
        map ( appId: { inherit appId; origin = "flathub-beta"; } ) cfg.betaPackages
      );
    };

    xdg.portal.enable = true;

  };

}
