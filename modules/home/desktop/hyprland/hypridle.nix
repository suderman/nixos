{
  config,
  lib,
  ...
}: let
  cfg = config.services.hypridle;
in {
  options.services.hypridle.lock = lib.mkOption {
    type = lib.types.str;
    default = "hyprlock";
    example = "swaylock";
  };
  # Timeout settings
  config.services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof ${cfg.lock} || ${cfg.lock}"; # avoid multiple instances
      };

      # Screenlock
      listener = [
        {
          timeout = 600;
          on-timeout = cfg.lock;
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  config.wayland.windowManager.hyprland.lua.features.hypridle = ''
    util.exec("num_lock", "sleep 1 && hyprctl dispatch dpms off")
  '';

  # Keyboard shortcut to turn off screen immediately with numlock
  config.wayland.windowManager.hyprland.settings = {
    bind = [", num_lock, exec, sleep 1 && hyprctl dispatch dpms off"];
  };
}
