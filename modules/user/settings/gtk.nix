{ config, lib, pkgs, user, ... }: {

  # gtk.enable = true;
  gtk = {
  
    gtk3.bookmarks = [
      "file:///home/${user}/ home"
      "sftp://lux/home/${user} lux"
    ];

    gtk3.extraCss = ''
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

    gtk3.extraConfig = {
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

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 0;
    };

  };

}
