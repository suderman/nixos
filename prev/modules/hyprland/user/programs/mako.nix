{ config, lib, pkgs, ... }: let

  cfg = config.services.mako;
  inherit (lib) getExe' mkIf mkDefault;

in {

  config = mkIf config.wayland.windowManager.hyprland.enable {

    services.mako = {
      enable = true;

      # settings = {
      #   default-timeout = 6000;
      #   progress-color = mkDefault "over #414559";
      #   border-radius = 7;
      #   border-color = mkDefault "#8caaee";
      #   border-size = 2;
      #   padding = "15";
      #   width = 600;
      #   height = 300;
      #   text-color = mkDefault "#c6d0f5";
      #   background-color = mkDefault "#303446";
      #   font = mkDefault "JetBrainsMono 11";
      #   anchor = "bottom-left";
      #   # "[urgency=normal]" = {
      #   #   border-color = "#ef9f76";
      #   # };
      #   # "[urgency=low]" = {
      #   #   border-color = "#ef9f76";
      #   # };
      #   # "[urgency=high]" = {
      #   #   border-color = "#ef9f76";
      #   #   default-timeout = "0";
      #   # };
      # };

      # extraConfig = ''
      #   [urgency=normal]
      #   border-color=#ef9f76
      #
      #   [urgency=low]
      #   border-color=#ef9f76
      #
      #   [urgency=high]
      #   border-color=#ef9f76
      #   default-timeout=0
      # '';
      # [mode=do-not-disturb]
      # invisible=1
    };

    wayland.windowManager.hyprland.settings = let 
      makoctl = getExe' config.services.mako.package "makoctl";
    in {
      bindn = [ ", escape, exec, ${makoctl} dismiss" ];
      bind = [ "super+alt, u, exec, ${makoctl} restore" ];
    };

  };

}
