{ config, lib, pkgs, ... }: let

  inherit (lib) mkIf removePrefix removeSuffix;
  urlToClass = url: removeSuffix "/" (removePrefix "http://" (removePrefix "https://" url));

  mkPWA = { name, icon, url }: {
    "chrome-${urlToClass url}__-Default" = {
      inherit name icon;
      exec = "chromium --ozone-platform-hint=auto --force-dark-mode --enable-features=WebUIDarkMode --app=\"${url}/\" %U";
    };
  };

  mkHidden = { name, icon, class }: {
    "${class}" = {
      inherit name icon;
      noDisplay = true;
    };
  }; 

in {
  config = mkIf config.wayland.windowManager.hyprland.enable {
    xdg.desktopEntries = {} //

      # Sushi (Quick Look)
      mkHidden {
        name = "Sushi"; 
        icon = "image-viewer"; 
        class = "org.gnome.NautilusPreviewer";
      } //

      # GIMP
      mkHidden {
        name = "GIMP"; 
        icon = "org.gimp.GIMP"; 
        class = "gimp-2.99";
      } //

      mkPWA { 
        name = "Immich"; 
        icon = "image-viewer"; 
        url = "https://immich.lux";
      } //

      mkPWA { 
        name = "SilverBullet"; 
        icon = "image-viewer"; 
        url = "https://silverbullet.lux";
      } //

    {};
  };
}
