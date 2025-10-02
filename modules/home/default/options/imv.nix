# programs.imv.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.imv;
  inherit (lib) mkIf;
  class = "imv";
in {
  config = mkIf cfg.enable {
    programs.imv = {
      settings = {
        options = {
          overlay = true;
          overlay_font = "monospace:18";
          title_text = "imv - [$imv_current_index/$imv_file_count] $imv_current_file";
          background = "checks";
        };
        binds = {
          # Navigation
          n = "next";
          p = "prev";
          gg = "goto 0";
          G = "goto -1";

          # Zooming
          "<minus>" = "zoom -1";
          "<equal>" = "zoom 1";
          c = "center";
          s = "scaling next";
          S = "upscaling next";
          a = "zoom actual";
          r = "reset";
          f = "fullscreen";

          # Rotate
          "<bracketleft>" = "rotate by -90";
          "<bracketright>" = "rotate by 90";

          # Panning
          j = "pan 0 10";
          k = "pan 0 -10";
          h = "pan -10 0";
          l = "pan 10 0";

          # Details
          d = "overlay";
          i = "exec ${lib.getExe pkgs.libnotify} -t 800 -u low -i image-x-generic \$imv_current_file";

          # Other commands
          q = "quit";
          x = "close";
          # D = "exec rm \"$imv_current_file\"; close"; # delete

          # Gif playback
          "<period>" = "next_frame";
          "<space>" = "toggle_playing";

          # Slideshow control
          t = "slideshow +1"; # start slideshow / increase delay by 1 second
          "<shift+t>" = "slideshow -1"; # decrease delay by 1 second
        };

        aliases = {
          "<Right>" = "next";
          "<Down>" = "next";
          "<Left>" = "prev";
          "<Up>" = "prev";
        };
      };
    };

    # Treat as media windows by hyprland
    wayland.windowManager.hyprland.settings = {
      windowrule = ["tag +media, class:(${class})"];
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
