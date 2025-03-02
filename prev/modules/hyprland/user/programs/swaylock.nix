{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkDefault mkForce;

in {

  config = mkIf cfg.enable {

    programs.swaylock = {
      enable = true;
      # package = pkgs.swaylock-effects;
      package = pkgs.swaylock;
      settings = {
        # grace = 2;
        # screenshots = true;
        # effect-blur = "7x5";
        # effect-vignette = "0.25:0.75";
        color = mkDefault "000000";
        font = mkDefault "monospace";
        line-color = mkDefault "000000";
        ring-color = mkDefault "ffffff70";
        # indicator = true;
        indicator-radius = 150;
        indicator-thickness = 30;
        show-failed-attempts = true;
        ignore-empty-password = true; 
      };
    };

    # Timeout settings
    services.hypridle = let
      inherit (config.home) username;
      notify-send = "${pkgs.libnotify}/bin/notify-send";
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
      swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    in {
      enable = true;
      settings = { 

        general = {
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof swaylock || ${swaylock}"; # avoid starting multiple hyprlock instances.
          # unlock_cmd = ""
          # before_sleep_cmd = ""
          # after_sleep_cmd = ""
        };

        # Screenlock
        listener = [{
          timeout = 600;
          on-timeout = "${swaylock}";
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

    # Keyboard shortcut to turn off screen immediately with numlock
    wayland.windowManager.hyprland.settings = {
      bind = [
        ", num_lock, exec, sleep 1 && hyprctl dispatch dpms off"
      ];
    };

  };

}
