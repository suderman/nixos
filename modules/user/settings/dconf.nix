{ ... }: {

  dconf.settings = {

    # Enable fractional scaling
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };

    # Gnome desktop
    "org/gnome/desktop/interface" = {
      clock-format = "12h";
      color-scheme = "prefer-dark";
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

    # Keyboard Shortcuts
    "org/gnome/desktop/wm/keybindings" = {
      close = "['<Super>q']";
      move-to-center = "['<Super>o']";
    };

  };

}
