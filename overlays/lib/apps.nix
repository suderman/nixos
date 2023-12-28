# this.lib.apps
{ pkgs, lib, this }: with pkgs; {

  # List of app ids or packages plucked from a list of apps
  ids = list: lib.unique (map (app: app.id) (list));
  packages = list: lib.unique (map (app: app.package) (list));

  # List all apps below
  nautilus = {
    id = "org.gnome.Nautilus.desktop";
    package = gnome.nautilus;
  };
  
  firefox = {
    id = "firefox.desktop";
    package = firefox;
  };

  text-editor = {
    id = "org.gnome.TextEditor.desktop";
    package = gnome-text-editor;
  };

  calculator = {
    id = "org.gnome.Calculator.desktop";
    package = gnome.gnome-calculator;
  };

  calendar = {
    id = "org.gnome.Calendar.desktop";
    package = gnome.gnome-calendar;
  };

  kitty = {
    id = "kitty.desktop";
    package = kitty;
  };

  telegram = {
    id = "org.telegram.desktop.desktop";
    package = telegram-desktop;
  };

  auto-move-windows = { 
    id = "auto-move-windows@gnome-shell-extensions.gcampax.github.com"; 
    package = gnomeExtensions.auto-move-windows; 
  };

  bluetooth-quick-connect = { 
    id = "bluetooth-quick-connect@bjarosze.gmail.com";
    package = gnomeExtensions.bluetooth-quick-connect;
  };

  blur-my-shell = {
    id = "blur-my-shell@aunetx";
    package = gnomeExtensions.blur-my-shell;
  };

  caffeine = {
    id = "caffeine@patapon.info";
    package = gnomeExtensions.caffeine;
  };

  hot-edge = {
    id = "hotedge@jonathan.jdoda.ca";
    package = gnomeExtensions.hot-edge;
  };

  native-window-placement = {
    id = "native-window-placement@gnome-shell-extensions.gcampax.github.com";
    package = gnomeExtensions.native-window-placement;
  };

  runcat = {
    id = "runcat@kolesnikov.se";
    package = gnomeExtensions.runcat;
  };

  user-themes = {
    id = "user-theme@gnome-shell-extensions.gcampax.github.com";
    package = gnomeExtensions.user-themes;
  };

  dash-to-dock = {
    id = "dash-to-dock@micxgx.gmail.com";
    package = gnomeExtensions.dash-to-dock;
  };

  dash2dock-lite = {
    id = "dash2dock-lite@icedman.github.com";
    package = gnomeExtensions.dash2dock-lite;
  };

}
