{ config, lib, pkgs, ... }: {

  services = {
    xserver = {
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = true;
      };
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
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.pano
  ];

  # Fix broken stuff
  # services.avahi.enable = false;
  # networking.networkmanager.enable = false;

}
