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
        enable = true;
        libinput.enable = true; # enable touchpad support
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
        displayManager.gdm.autoSuspend = true;
      };
      geoclue2.enable = true;
      gnome.games.enable = true;
    };

    environment = {

      systemPackages = with pkgs; [
        gnome.gnome-software
        gnome.gnome-tweaks
        gnome.dconf-editor
        chrome-gnome-shell
        wl-clipboard
        shairplay

        gnomeExtensions.appindicator
        gnomeExtensions.bluetooth-quick-connect
        gnomeExtensions.blur-my-shell
        gnomeExtensions.browser-tabs
        gnomeExtensions.caffeine
        gnomeExtensions.gnome-40-ui-improvements
        gnomeExtensions.gtk-title-bar
        gnomeExtensions.hot-edge
        gnomeExtensions.just-perfection
        gnomeExtensions.no-titlebar-when-maximized
        gnomeExtensions.runcat
        gnomeExtensions.gsconnect
        gnomeExtensions.sound-output-device-chooser

        # gnomeExtensions.vitals
        # gnomeExtensions.tray-icons-reloaded
        # gnomeExtensions.clipboard-history
        # gnomeExtensions.clipboard-indicator
        # gnomeExtensions.custom-hot-corners-extended
        # gnomeExtensions.espresso
        # gnomeExtensions.x11-gestures
        # gnomeExtensions.pano gsound libgda

      ];

      variables = {
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

    };

    # Enable sound.
    sound.enable = true;
    services.pipewire.enable = true;
  
    # Fix broken stuff
    # services.avahi.enable = false;
    # networking.networkmanager.enable = false;

    # persist.dirs = [ "/var/lib/AccountsService" ];
    # persist.home.dirs = [ 
    #   ".local/share/Trash"
    #   ".local/share/keyrings" 
    # ];

  };

}
