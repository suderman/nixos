{ config, lib, pkgs, ... }: 

{
  gtk.enable = true;
  # gtk.font.name = "Noto Sans";
  # gtk.font.package = pkgs.noto-fonts;
  # gtk.theme.name = "Dracula";
  # gtk.theme.package = unstable.dracula-theme;
  # gtk.iconTheme.name = "Papirus-Dark-Maia";  # Candy and Tela also look good
  # gtk.iconTheme.package = unstable.papirus-maia-icon-theme;
  # gtk.gtk3.extraConfig = {
  #   gtk-application-prefer-dark-theme = true;
  #   gtk-key-theme-name    = "Emacs";
  #   gtk-icon-theme-name   = "Papirus-Dark-Maia";
  #   gtk-cursor-theme-name = "capitaine-cursors";
  # };

  gtk.gtk3.bookmarks = [
    "file:///home/me/work"
    "file:///home/me/data"
    "sftp://lux/home/me lux"
  ];

  gtk.gtk3.extraCss = ''
    /* x11 and xwayland windows */
    window.ssd headerbar.titlebar {
        padding-top: 0;
        padding-bottom: 0;
        min-height: 0;
        border: none;
        background-image: linear-gradient(to bottom, shade(@theme_bg_color, 1.05), shade(@theme_bg_color, 1.00));
        box-shadow: inset 0 1px shade(@theme_bg_color, 1.4);
    }

    window.ssd headerbar.titlebar button.titlebutton {
        padding: 0px;
        min-height: 0;
        min-width: 0;
        background-color: transparent;
    }

    /* native wayland ssd windows */
    .default-decoration {
        padding: 3px;
        min-height: 0;
        border: none;
        background-image: linear-gradient(to bottom, shade(@theme_bg_color, 1.05), shade(@theme_bg_color, 1.00));
        box-shadow: inset 0 1px shade(@theme_bg_color, 1.4);
    }

    .default-decoration .titlebutton {
        padding: 0px;
        min-height: 0;
        min-width: 0;
    }
  '';

  gtk.gtk3.extraConfig = {
    gtk-theme-name = "Materia-dark-compact";
    gtk-icon-theme-name = "Adwaita";
    gtk-font-name = "System-ui = 8";
    gtk-cursor-theme-name = "Adwaita";
    gtk-cursor-theme-size = 0;
    gtk-toolbar-style = "GTK_TOOLBAR_BOTH";
    gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
    gtk-button-images = 1;
    gtk-menu-images = 1;
    gtk-enable-event-sounds = 1;
    gtk-enable-input-feedback-sounds = 1;
    gtk-xft-antialias = 1;
    gtk-xft-hinting = 1;
    gtk-xft-hintstyle = "hintfull";
    gtk-key-theme-name = "Emacs";
    gtk-application-prefer-dark-theme = 0;
  };

  gtk.gtk4.extraConfig = {
    gtk-application-prefer-dark-theme = 0;
  };

  dconf.settings = {
    # "org/gnome/desktop/interface" = {
    #   gtk-key-theme = "Emacs";
    #   cursor-theme = "Capitaine Cursors";
    # };
    "org/gnome/desktop/peripherals/touchpad" = {
      disable-while-typing = true;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      natural-scroll = true;
      speed = "0.30882352941176472";
    };
    "org/gnome/desktop/wm/keybindings" = {
      close = "['<Super>q']";
      move-to-center = "['<Super>o']";
    };
  };
  # xdg.systemDirs.data = [
  #   "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  #   "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  # ];

}
