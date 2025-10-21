{
  lib,
  pkgs,
  ...
}: {
  # Lockscreen
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock;
    settings = {
      color = lib.mkDefault "000000";
      font = lib.mkDefault "monospace";
      line-color = lib.mkDefault "000000";
      ring-color = lib.mkDefault "ffffff70";
      indicator-radius = 150;
      indicator-thickness = 30;
      show-failed-attempts = true;
      ignore-empty-password = true;
    };
  };

  # Timeout settings
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore_dbus_inhibit = false;
        # avoid starting multiple hyprlock instances
        lock_cmd = "pidof swaylock || swaylock";
      };

      # Screenlock
      listener = [
        {
          timeout = 600;
          on-timeout = "swaylock";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # Keyboard shortcut to turn off screen immediately with numlock
  wayland.windowManager.hyprland.settings = {
    bind = [
      ", num_lock, exec, sleep 1 && hyprctl dispatch dpms off"
    ];
  };
}
