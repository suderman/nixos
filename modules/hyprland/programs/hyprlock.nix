{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkForce;

in {

  config = mkIf cfg.enable {

    programs.hyprlock = {
      enable = true;
      settings = {

        general = {
          disable_loading_bar = true;
          grace = 10;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = [{
          path = "screenshot";
          blur_size = 4;
          blur_passes = 3;
          noise = 0.0117;
          contrast = 1.3000;
          brightness = 0.8000;
          vibrancy = 0.2100;
          vibrancy_darkness = 0.0;
        }];

        input-field = [{
          monitor = "";
          size = "250, 50";
          outline_thickness = 3;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.64; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          fade_on_empty = true;
          placeholder_text = "<i>Password...</i>"; # Text rendered in the input box when it's empty.
          hide_input = false;
          position = "0, 80";
          halign = "center";
          valign = "bottom";
        }];

        label = [

          # Current time
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<b><big> $(date +"%H:%M:%S") </big></b>"'';
            font_size = 64;
            position = "0, 16";
            halign = "center";
            valign = "center";

          # User label
          } {
            monitor = "";
            text = ''Hey <span text_transform="capitalize" size="larger">$USER</span>'';
            font_size = 20;
            position = "0, 0";
            halign = "center";
            valign = "center";

          # Type to unlock
          } {
            monitor = "";
            text = "Type to unlock!";
            font_size = 16;
            position = "0, 30";
            halign = "center";
            valign = "bottom";
          }

        ];

      };
    };

    # Timeout settings
    services.hypridle = let
      inherit (config.home) username;
      notify-send = "${pkgs.libnotify}/bin/notify-send";
      hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    in {
      enable = true;
      settings = { 

        general = {
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || ${hyprlock}"; # avoid starting multiple hyprlock instances.
          # unlock_cmd = ""
          # before_sleep_cmd = ""
          # after_sleep_cmd = ""
        };

        # Screenlock
        listener = [{
          timeout = 600;
          on-timeout = "${hyprlock}";
          # on-resume = ${notify-send} "Welcome back ${username}!"

        # Screen off
        } {
          timeout = 1200;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }];

      };
    };

    systemd.user.services.hypridle = {
      Install.WantedBy = mkForce [ cfg.systemd.target ];
      Unit.PartOf = mkForce [ cfg.systemd.target ];
      Unit.After = mkForce [ cfg.systemd.target ]; 
    };

  };

}
