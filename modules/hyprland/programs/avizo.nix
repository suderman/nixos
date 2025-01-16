{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkForce;

in {

  config = mkIf cfg.enable {

    systemd.user.services.avizo = {
      Install.WantedBy = mkForce [ cfg.systemd.target ];
      Unit.PartOf = mkForce [ cfg.systemd.target ];
      Unit.After = mkForce [ cfg.systemd.target ]; 
    };

    services.avizo = {
      enable = true;
      settings = {

        # https://github.com/misterdanb/avizo/blob/master/config.ini
        default = {
          time = 1.0;
          y-offset = 0.5;
          fade-in = 0.1;
          fade-out = 0.2;
          padding = 10;
        };

      };
    };

    wayland.windowManager.hyprland.settings = {
      binde = [

        # Screen brightness
        ", XF86MonBrightnessUp, exec, lightctl up"
        ", XF86MonBrightnessDown, exec, lightctl down"

        # Volume control
        ", XF86AudioRaiseVolume, exec, volumectl -pbu up"
        ", XF86AudioLowerVolume, exec, volumectl -pb down"

      ];
      bind = [

        # Mute toggle
        ", XF86AudioMute, exec, volumectl -a toggle-mute"
        ", XF86AudioMicMute, exec, volumectl -am toggle-mute"

      ];
    };

  };

}
