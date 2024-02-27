# Modify existing packages
{ final, prev, ... }: let

  inherit (prev) lib this;
  inherit (this.lib) enableWayland appId;

in {

  # These packages support Wayland but sometimes need to be persuaded
  digikam          = enableWayland { type = "qt"; pkg = prev.digikam; bin = "digikam"; };
  dolphin          = enableWayland { type = "qt"; pkg = prev.dolphin; bin = "dolphin"; };
  element-desktop  = enableWayland { type = "electron"; pkg = prev.element-desktop; bin = "element-desktop"; };
  figma-linux      = enableWayland { type = "electron"; pkg = prev.figma-linux; bin = "figma-linux"; };
  nextcloud-client = enableWayland { type = "qt"; pkg = prev.nextcloud-client; bin = "nextcloud"; };
  # owncloud-client  = enableWayland { type = "qt"; pkg = prev.owncloud-client; bin = "owncloud"; };
  plexamp          = enableWayland { type = "electron"; pkg = prev.plexamp; bin = "plexamp"; };
  signal-desktop   = enableWayland { type = "electron"; pkg = prev.signal-desktop; bin = "signal-desktop"; };
  # _1password-gui  = enableWayland { type = "electron"; pkg = prev._1password-gui; bin = "1password"; };

  # Add appId to existing packages meta
  firefox = appId "firefox.desktop" prev.firefox;
  gnome-text-editor = appId "org.gnome.TextEditor.desktop" prev.gnome-text-editor;
  gnome = with prev.gnome; prev.gnome // {
    gnome-calculator = appId "org.gnome.Calculator.desktop" gnome-calendar;
    gnome-calendar = appId "org.gnome.Calendar.desktop" gnome-calendar;
    nautilus = appId "org.gnome.Nautilus.desktop" nautilus;
  };
  gnomeExtensions = with prev.gnomeExtensions; prev.gnomeExtensions // {
    auto-move-windows = appId "auto-move-windows@gnome-shell-extensions.gcampax.github.com" auto-move-windows;
    bluetooth-quick-connect = appId "bluetooth-quick-connect@bjarosze.gmail.com" bluetooth-quick-connect;
    blur-my-shell = appId "blur-my-shell@aunetx" blur-my-shell;
    caffeine = appId "caffeine@patapon.info" caffeine;
    dash-to-dock = appId "dash-to-dock@micxgx.gmail.com" dash-to-dock;
    dash2dock-lite = appId "dash2dock-lite@icedman.github.com" dash2dock-lite;
    gsconnect = appId "gsconnect@andyholmes.github.io" gsconnect;
    hot-edge = appId "hotedge@jonathan.jdoda.ca" hot-edge;
    native-window-placement = appId "native-window-placement@gnome-shell-extensions.gcampax.github.com" native-window-placement;
    runcat = appId "runcat@kolesnikov.se" runcat;
    user-themes = appId "user-theme@gnome-shell-extensions.gcampax.github.com" user-themes;
  };
  kitty = appId "kitty.desktop" prev.kitty;
  tauon = appId "tauonmb.desktop" prev.tauon;
  telegram-desktop = appId "org.telegram.desktop.desktop" prev.telegram-desktop;

} 
