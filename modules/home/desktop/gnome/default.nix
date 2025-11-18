{
  pkgs,
  flake,
  ...
}: {
  imports = [flake.homeModules.desktop.default];

  config = {
    programs.gnome-shell.enable = true;

    home.packages = with pkgs.gnomeExtensions; [
      auto-move-windows
      bluetooth-quick-connect
      blur-my-shell
      caffeine
      dash-to-dock
      native-window-placement
      runcat
      user-themes
    ];

    # Configure dconf
    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
      };

      # Enable fractional scaling
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer"];
      };

      # Gnome desktop
      "org/gnome/desktop/interface" = {
        clock-format = "12h";
        color-scheme = "default"; # prefer-dark prefer-light default
        show-battery-percentage = true;
      };

      # Resize windows while holding super
      "org/gnome/desktop/wm/preferences" = {
        resize-with-right-button = true;
      };

      # Touchpad preferences
      "org/gnome/desktop/peripherals/touchpad" = {
        disable-while-typing = true;
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
        natural-scroll = true;
        speed = "0.30882352941176472";
      };

      # Power button suspends system
      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "interactive"; # default is suspend
        sleep-inactive-battery-type = "suspend"; # when battery: idle means hibernate
        sleep-inactive-battery-timeout = "1800"; # when battery: idle after half hour
        sleep-inactive-ac-type = "nothing"; # when ac: idle means do nothing (just let screensaver lock occur)
        sleep-inactive-ac-timeout = "0"; # when ac: don't idle at all
      };
    };

    persist.storage.directories = [
      ".config/dconf"
      ".config/gnome-shell"
      ".local/share/gnome-shell"
      ".local/share/icons"
      ".local/share/fonts"
      ".local/share/themes"
      ".local/share/applications"
      ".config/gtk-3.0"
      ".config/gtk-4.0"
    ];

    persist.scratch.directories = [
      ".config/gnome-session"
      ".local/share/gnome-session"
    ];
  };
}
