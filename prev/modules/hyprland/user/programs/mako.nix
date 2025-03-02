{ config, lib, pkgs, ... }: let

  cfg = config.services.mako;
  inherit (lib) getExe' mkIf mkDefault;

in {

  config = mkIf config.wayland.windowManager.hyprland.enable {

    services.mako = {
      enable = true;
      font = mkDefault "JetBrainsMono 11";
      anchor = "bottom-left";
      width = 600;
      height = 300;
      borderRadius = 7;
      borderSize = 2;
      padding = "15";
      defaultTimeout = 6000;

      backgroundColor = mkDefault "#303446";
      textColor = mkDefault "#c6d0f5";
      borderColor = mkDefault "#8caaee";
      progressColor = mkDefault "over #414559";

      extraConfig = ''
        [urgency=normal]
        border-color=#ef9f76

        [urgency=low]
        border-color=#ef9f76

        [urgency=high]
        border-color=#ef9f76
        default-timeout=0
      '';
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
