{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.playerctld.enable = true; 
    home.packages = [ pkgs.playerctl ];

    wayland.windowManager.hyprland.settings = {
      bindl = [
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioStop, exec, playerctl pause"
        ", XF86AudioPause, exec, playerctl pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
      ];
    };

  };

}
