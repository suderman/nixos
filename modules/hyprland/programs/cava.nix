# Audio visualizer
{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
      cava 
    ];

    xdg.configFile."cava/config".text = ''
      [input]
      method = pulse
      source = auto
    '';
  };

}
