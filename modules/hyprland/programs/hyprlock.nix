{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    programs.hyprlock = {
      enable = true;
    };

    xdg.configFile."hypr/hyprlock.conf".text = ''
      background {
        monitor =
        # path = $HOME/.config/wallpapers/{config.theme.wallpaper}
        # color = rgb({config.theme.colors.bg})

        blur_size = 4
        blur_passes = 3
        noise = 0.0117
        contrast = 1.3000
        brightness = 0.8000
        vibrancy = 0.2100
        vibrancy_darkness = 0.0
      }

      input-field {
        monitor =
        size = 250, 50
        outline_thickness = 3
        dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.64 # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true
        # outer_color = rgb({config.theme.colors.primary-bg})
        # inner_color = rgb({config.theme.colors.bg})
        # font_color = rgb({config.theme.colors.fg})
        fade_on_empty = true
        placeholder_text = <i>Password...</i> # Text rendered in the input box when it's empty.
        hide_input = false
        position = 0, 80
        halign = center
        valign = bottom
      }

      # Current time
      label {
        monitor =
        text = cmd[update:1000] echo "<b><big> $(date +"%H:%M:%S") </big></b>"
        # color = rgb({config.theme.colors.fg})
        font_size = 64
        # font_family = {config.theme.font}
        position = 0, 16
        halign = center
        valign = center
      }

      # User label
      label {
        monitor =
        text = Hey <span text_transform="capitalize" size="larger">$USER</span>
        # color = rgb({config.theme.colors.fg})
        font_size = 20
        # font_family = {config.theme.font}
        position = 0, 0
        halign = center
        valign = center
      }

      # Type to unlock
      label {
        monitor =
        text = Type to unlock!
        # color = rgb({config.theme.colors.fg})
        font_size = 16
        # font_family = {config.theme.font}
        position = 0, 30
        halign = center
        valign = bottom
      }
    '';

    # Timeout settings
    xdg.configFile."hypr/hypridle.conf".text = let 
      inherit (config.home) username;
      notify-send = "${pkgs.libnotify}/bin/notify-send";
      hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
    in ''
      general {
        ignore_dbus_inhibit = false
        lock_cmd = pidof hyprlock || ${hyprlock} # avoid starting multiple hyprlock instances.
        # unlock_cmd = ""
        # before_sleep_cmd = ""
        # after_sleep_cmd = ""
      }

      # Screenlock
      listener {
        timeout = 600
        on-timeout = ${hyprlock}
        # on-resume = ${notify-send} "Welcome back ${username}!"
      }

      # Suspend 
      # listener {
      #     timeout = 660
      #     on-timeout = systemctl suspend
      # }
    '';

  };

}
