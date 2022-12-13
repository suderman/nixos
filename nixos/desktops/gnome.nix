{ config, lib, pkgs, ... }:

with pkgs; 

let 
  cfg = config.desktops.gnome;

in {
  options = {
    desktops.gnome.enable = lib.options.mkEnableOption "gnome"; 
  };

  # desktops.gnome.enable = true;
  config = lib.mkIf cfg.enable {

    services = {
      xserver = {
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
        displayManager.gdm.autoSuspend = true;
      };
      geoclue2.enable = true;
      gnome.games.enable = true;
    };

    environment.systemPackages = with pkgs; [
      gnome.gnome-software
      gnome.gnome-tweaks
      gnome.dconf-editor
      chrome-gnome-shell
      gnomeExtensions.appindicator
      gnomeExtensions.bluetooth-quick-connect
      gnomeExtensions.just-perfection
      gnomeExtensions.gnome-40-ui-improvements
      gnomeExtensions.blur-my-shell
      gnomeExtensions.clipboard-indicator
      # gnomeExtensions.custom-hot-corners-extended
      gnomeExtensions.hot-edge
      gnomeExtensions.vitals
      gnomeExtensions.caffeine
      gnomeExtensions.runcat
      # gnomeExtensions.espresso
      # gnomeExtensions.gsconnect
      # gnomeExtensions.x11-gestures
      gnomeExtensions.no-titlebar-when-maximized
      gnomeExtensions.gtk-title-bar
      gnomeExtensions.clipboard-history
      gnomeExtensions.tray-icons-reloaded
      # gnomeExtensions.sound-output-device-chooser
      # gnomeExtensions.pano gsound libgda
    ];

    environment.variables = {
      WAYLAND_DISPLAY = "wayland-0";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      # QT_WAYLAND_FORCE_DPI = "physical";
      # QT_SCALE_FACTOR = "1.25";
      # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # SAL_USE_VCLPLUGIN = "gtk3";
      NIXOS_OZONE_WL = "1";
    };

    # Fix broken stuff
    # services.avahi.enable = false;
    # networking.networkmanager.enable = false;

  };

}
