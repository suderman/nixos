{
  config,
  osConfig,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.gnome-shell;
  inherit (lib) mkOption types;
in {
  imports = [flake.homeModules.desktop.default];

  # options.programs.gnome-shell = with types; {
  #   meta = mkOption {
  #     type = anything;
  #     default = {};
  #   };
  #
  #   dock = mkOption {
  #     type = listOf (either package str);
  #     default = with pkgs; [
  #       kitty
  #       firefox
  #       nautilus
  #       telegram-desktop
  #       gnome-text-editor
  #     ];
  #   };
  #
  #   packages = mkOption {
  #     type = listOf package;
  #     default = with pkgs; [
  #       dconf
  #       chrome-gnome-shell
  #       epiphany
  #       gnome-software
  #       gnome-tweaks
  #       dconf-editor
  #     ];
  #   };
  #
  #   # `gnome-extensions list` for a list
  #   gnome-extensions = mkOption {
  #     type = listOf package;
  #     default = with pkgs.gnomeExtensions; [
  #       auto-move-windows
  #       bluetooth-quick-connect
  #       blur-my-shell
  #       caffeine
  #       native-window-placement
  #       runcat
  #       user-themes
  #     ];
  #   };
  #
  #   wallpapers = mkOption {
  #     type = listOf (either str path);
  #     default = let
  #       dir = "/run/current-system/sw/share/backgrounds/gnome";
  #     in [
  #       "${dir}/adwaita-l.jpg"
  #       "${dir}/adwaita-d.jpg"
  #     ];
  #   };
  # };

  config = {
    programs.gnome-shell.enable = true;

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
