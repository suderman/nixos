{ config, pkgs, ... }: with pkgs; {

  nautilus = {
    id = "org.gnome.Nautilus.desktop";
    pkg = gnome.nautilus;
  };
  
  firefox = {
    id = "firefox.desktop";
    pkg = firefox;
  };

  text-editor = {
    id = "org.gnome.TextEditor.desktop";
    pkg = gnome-text-editor;
  };

  kitty = {
    id = "kitty.desktop";
    pkg = kitty;
  };

  telegram = {
    id = "org.telegram.desktop.desktop";
    pkg = telegram-desktop;
  };

  auto-move-windows = { 
    id = "auto-move-windows@gnome-shell-extensions.gcampax.github.com"; 
    pkg = gnomeExtensions.auto-move-windows; 
  };

  bluetooth-quick-connect = { 
    id = "bluetooth-quick-connect@bjarosze.gmail.com";
    pkg = gnomeExtensions.bluetooth-quick-connect;
  };

  blur-my-shell = {
    id = "blur-my-shell@aunetx";
    pkg = gnomeExtensions.blur-my-shell;
  };

  caffeine = {
    id = "caffeine@patapon.info";
    pkg = gnomeExtensions.caffeine;
  };

  hot-edge = {
    id = "hotedge@jonathan.jdoda.ca";
    pkg = gnomeExtensions.hot-edge;
  };

  native-window-placement = {
    id = "native-window-placement@gnome-shell-extensions.gcampax.github.com";
    pkg = gnomeExtensions.native-window-placement;
  };

  runcat = {
    id = "runcat@kolesnikov.se";
    pkg = gnomeExtensions.runcat;
  };

  user-themes = {
    id = "user-theme@gnome-shell-extensions.gcampax.github.com";
    pkg = gnomeExtensions.user-themes;
  };

}
