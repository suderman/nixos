# desktop = "hyprland";
{ config, lib, pkgs, inputs, desktop, ... }: 

let 
  inherit (lib) mkIf mkOption mkBefore types;

in {

  # Import hyprland module
  imports = [ inputs.hyprland.nixosModules.default ];

  config = mkIf (desktop == "hyprland") {

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

  };

}
