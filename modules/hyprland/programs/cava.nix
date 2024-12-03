# Audio visualizer
{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    programs.cava = {
      enable = false;
      settings = {

        input = {
          method = "pulse";
          source = "auto";
        };

      };
    };

  };

}
