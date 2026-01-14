# programs.imv.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.imv;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;
  class = "imv";
in {
  config = mkIf cfg.enable {
    programs.imv = {
      settings = {
        options = {
          overlay = false;
          overlay_font = "monospace:18";
          title_text = "imv - [$imv_current_index/$imv_file_count] $imv_current_file";
          background = "checks";
        };
        binds = {
          f = "next";
          "<Shift+B>" = "next";
          "<space>" = "next";
          "<bracketright>" = "next";
          "<right>" = "prev";

          b = "prev";
          "<Shift+F>" = "prev";
          "<Shift+space>" = "prev";
          "<bracketleft>" = "prev";
          "<left>" = "prev";

          gg = "goto 0";
          G = "goto -1";

          # Zooming
          "<minus>" = "zoom -1";
          "<up>" = "zoom -1";
          "<equal>" = "zoom 1";
          "<down>" = "zoom 1";
          c = "center";
          "<backslash>" = "scaling full";
          "0" = "scaling none";
          s = "scaling next";

          # Rotate
          r = "rotate by 90";
          "<Shift+R>" = "rotate by -90";

          # Panning
          j = "pan 0 -10";
          k = "pan 0 10";
          h = "pan 10 0";
          l = "pan -10 0";

          # Details
          i = "overlay";
          d = "exec ${lib.getExe pkgs.libnotify} -t 800 -u low -i image-x-generic \$imv_current_file";

          # Other commands
          q = "quit";
          x = "close";
          # D = "exec rm \"$imv_current_file\"; close"; # delete

          # Gif playback
          "<period>" = "next_frame";
          "<comma>" = "toggle_playing";

          # Slideshow control
          t = "slideshow +1"; # start slideshow / increase delay by 1 second
          "<Shift+T>" = "slideshow -1"; # decrease delay by 1 second
        };
      };
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "tab" = "f"; # next
      "shift.tab" = "b"; # previous
    };

    # Treat as media windows by hyprland
    wayland.windowManager.hyprland.settings = {
      windowrule = ["tag +media, match:class (${class})"];
    };

    # Make default application for images
    xdg.mimeApps.defaultApplications = {
      "image/png" = ["imv.desktop"];
      "image/jpeg" = ["imv.desktop"];
      "image/jpg" = ["imv.desktop"];
      "image/gif" = ["imv.desktop"];
      "image/bmp" = ["imv.desktop"];
      "image/webp" = ["imv.desktop"];
      "image/svg+xml" = ["imv.desktop"];
      "image/tiff" = ["imv.desktop"];
      "image/x-icon" = ["imv.desktop"];
      "image/*" = ["imv.desktop"];
    };

    # Do the same in Yazi
    programs.yazi.settings.opener.image = [
      {
        run = ''imv "$@"'';
        desc = "View in imv";
        block = false;
        orphan = true;
        for = "unix";
      }
    ];
  };
}
