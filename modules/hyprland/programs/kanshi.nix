{ config, lib, pkgs, this, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
      kanshi
      wdisplays
    ];

    services.kanshi = {
      enable = true;
      systemdTarget = "hyprland-session.target";
      settings = [{ 

        profile = {
          name = "undocked";
          outputs = [{
            criteria = "eDP-1";
          }];
        };

      }{

        profile = {
          name = "desktop";
          outputs = [{
            criteria = "Ancor Communications Inc ASUS PB278 EBLMTF138523";
            # criteria = "Ancor Communications Inc ASUS PB278";
            # criteria = "DP-1";
            mode = "2560x1440";
            position = "0,0";
            status = "enable";
            transform = "normal"; # "normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"
            scale = 1.0;
          }{
            criteria = "Unknown-1";
            status = "disable";
          }];
        };

      }];

    };
  };

}
