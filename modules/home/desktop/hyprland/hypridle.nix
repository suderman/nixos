{...}: let
  lock = "hyprlock"; # or swaylock
in {
  # Timeout settings
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore_dbus_inhibit = false;
        # avoid starting multiple hyprlock instances
        lock_cmd = "pidof ${lock} || ${lock}";
      };

      # Screenlock
      listener = [
        {
          timeout = 600;
          on-timeout = lock;
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
    bind = [", num_lock, exec, sleep 1 && hyprctl dispatch dpms off"];
  };
}
