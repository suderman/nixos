{ config, osConfig, lib, pkgs, flake, ... }: let 

  cfg = config.programs.gnome-shell;
  inherit (lib) mkOption types;

in {

  imports = [ flake.homeModules.desktop ];

  options.programs.gnome-shell = with types; {
    meta = mkOption { type = anything; default = {}; };

    dock = mkOption { 
      type = listOf (either package str);
      default = with pkgs; [
        kitty
        firefox
        nautilus
        telegram-desktop
        gnome-text-editor
      ]; 
    };

    packages = mkOption {
      type = listOf package;
      default = with pkgs; [
        dconf 
        chrome-gnome-shell
        epiphany
        gnome-software 
        gnome-tweaks
        dconf-editor
      ];
    };

    # `gnome-extensions list` for a list
    gnome-extensions = mkOption { 
      type = listOf package; 
      default = with pkgs.gnomeExtensions; [
        auto-move-windows
        bluetooth-quick-connect
        blur-my-shell
        caffeine
        native-window-placement
        runcat
        user-themes
      ];
    };

    wallpapers = mkOption {
      type = listOf (either str path);
      default = let dir = "/run/current-system/sw/share/backgrounds/gnome"; in [
        "${dir}/adwaita-l.jpg"
        "${dir}/adwaita-d.jpg"
      ];
    };

  };


  config = {

    programs.gnome-shell = {
      enable = true;
    };

    # Install all missing packages and extentions
    home.packages = let 
      inherit (lib) unique filter isString subtractLists;
      allPkgs = unique( cfg.packages ++ cfg.dock ++ cfg.gnome-extensions );
      userPkgs = filter (pkg: ! isString pkg) allPkgs;
      systemPkgs = osConfig.environment.systemPackages;
      # systemPkgs = [];
    in subtractLists systemPkgs userPkgs;

    # Install all missing flatpak packages
    services.flatpak.packages = let
      inherit (lib) unique filter isString subtractLists;
      allPkgs = unique( cfg.packages ++ cfg.dock ++ cfg.gnome-extensions );
      userPkgs = filter (pkg: isString pkg) allPkgs;
      systemPkgs = osConfig.services.flatpak.all;
      # systemPkgs = [];
    in subtractLists systemPkgs userPkgs;


    # Configure dconf
    dconf.settings = let
      inherit (builtins) head tail toString;
      # inherit (this.lib) appIds;
    in {

      "org/gnome/shell" = {
        disable-user-extensions = false;
        # enabled-extensions = appIds cfg.gnome-extensions; 
        # favorite-apps = appIds cfg.dock;
      };

      # "org/gnome/desktop/background" = {
      #   picture-uri = "file://" + toString( head cfg.wallpapers );
      #   picture-uri-dark = "file://" + toString( tail cfg.wallpapers );
      # };


      # Enable fractional scaling
      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
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

      # # Keyboard Shortcuts
      # "org/gnome/desktop/wm/keybindings" = {
      #   activate-window-menu = "@as []";
      #   toggle-message-tray = "@as []";
      #   close = "['<Super>q', '<Alt>F4']";
      #   minimize = "['<Super>comma']";
      #   toggle-maximized = "['<Super>m']";
      #   move-to-center = "['<Super>o']";
      # };

      # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      #   name = "kitty super";
      #   command = "kitty";
      #   binding = "<Super>Return";
      # };

    };

    # # Persist extra config
    # persist.directories = [ ".config/hypr/extra" ];
    # tmpfiles.files = [ ".config/hypr/extra/hyprland.conf" ];

  };

}
