# programs.dconf.enable = true;
{ config, lib, pkgs, ... }:

let 
  cfg = config.programs.dconf;

in {

  options = {
    programs.dconf.enable = lib.options.mkEnableOption "dconf"; 
  };

  config = lib.mkIf cfg.enable {

    # Install dconf
    home.packages = with pkgs; [ dconf ];

    # Configure dconf
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

      # # Power button suspends system
      # "org/gnome/settings-daemon/plugins/power" = {
      #   power-button-action = "hibernate"; # default: suspend
      # };

      # Power button suspends system
      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "hibernate"; # default is suspend
        sleep-inactive-battery-type = "hibernate"; # when battery: idle means hibernate 
        sleep-inactive-battery-timeout = "1800"; # when battery: idle after half hour
        sleep-inactive-ac-type = "nothing"; # when ac: idle means do nothing (just let screensaver lock occur) 
        sleep-inactive-ac-timeout = "0"; # when ac: don't idle at all
      };

      # Keyboard Shortcuts
      "org/gnome/desktop/wm/keybindings" = {
        activate-window-menu = "@as []";
        toggle-message-tray = "@as []";
        close = "['<Super>q', '<Alt>F4']";
        minimize = "['<Super>comma']";
        toggle-maximized = "['<Super>m']";
        move-to-center = "['<Super>o']";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "kitty super";
        command = "kitty -e tmux";
        binding = "<Super>Return";
      };

    };

  };

}
