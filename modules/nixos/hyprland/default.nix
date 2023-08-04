# modules.hyprland.enable = true;
{ config, lib, pkgs, inputs, ... }: 

let 

  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkOption mkBefore types;

in {

  # Import hyprland module
  imports = [ inputs.hyprland.nixosModules.default ];

  options.modules.hyprland = {
    enable = lib.options.mkEnableOption "hyprland"; 
  };

  config = mkIf cfg.enable {

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

  };

}


