# modules.gnome.enable = true;
{ config, lib, pkgs, ... }:

let 

  cfg = config.modules.gnome;
  home = config.users.users."${config.users.user}".home;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.gnome = {
    enable = lib.options.mkEnableOption "gnome"; 
  };

  config = mkIf cfg.enable {

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

    # xdg.portal = {
    #   enable = true;
    #   extraPortals = with pkgs; [
    #     xdg-desktop-portal-wlr
    #     xdg-desktop-portal-gtk
    #   ];
    # };

    environment = {

      systemPackages = with pkgs; [
        gnome.gnome-software 
        gnome.gnome-tweaks
        gnome.dconf-editor
        chrome-gnome-shell
        wl-clipboard
        # shairplay
        unstable.epiphany

        gnomeExtensions.appindicator
        gnomeExtensions.bluetooth-quick-connect
        gnomeExtensions.blur-my-shell
        # gnomeExtensions.browser-tabs
        gnomeExtensions.caffeine
        gnomeExtensions.gnome-40-ui-improvements
        gnomeExtensions.gtk-title-bar
        gnomeExtensions.hot-edge
        gnomeExtensions.just-perfection
        gnomeExtensions.no-titlebar-when-maximized
        gnomeExtensions.runcat
        gnomeExtensions.gsconnect
        # gnomeExtensions.sound-output-device-chooser
        gnomeExtensions.another-window-session-manager
        gnomeExtensions.zoom-wayland-extension

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
        # WAYLAND_DISPLAY = "wayland-0";
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

    # Gnome has a hard-coded screenshots directory
    # Watch that directory for screenshots, move contents to new directory and delete old
    # https://discourse.gnome.org/t/feature-request-change-screenshot-directory/14001/9
    systemd = let old = "${home}/data/images/Screenshots"; new = "${home}/data/images/screens"; in { 

      # Watch the "old" path and when it exists, trigger the ssmv service
      paths.ssmv = {
        wantedBy = [ "paths.target" ];
        pathConfig = {
          PathExists = old;
          Unit = "ssmv.service";
        };
      };

      # Move all files inside the "old" directory into the "new" and delete the "old" directory
      services.ssmv = {
        description = "Moves files from ${old} to ${new} and deletes ${old}";
        requires = [ "ssmv.path" ];
        serviceConfig.Type = "oneshot";
        script = "mv ${old}/* ${new}/ && rmdir --ignore-fail-on-non-empty ${old}";
      };

    };

  };

}
