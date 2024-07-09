{ config, lib, pkgs, ... }: let

  cfg = config.services.mako;
  inherit (lib) mkIf;

in {

  config = mkIf config.wayland.windowManager.hyprland.enable {

    services.mako = {
      enable = true;
      font = "JetBrainsMono 11";
      anchor = "top-center";
      width = 600;
      height = 300;
      borderRadius = 7;
      borderSize = 2;
      padding = "15";
      defaultTimeout = 6000;

      backgroundColor = "#303446";
      textColor = "#c6d0f5";
      borderColor = "#8caaee";
      progressColor = "over #414559";

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

  };

}
