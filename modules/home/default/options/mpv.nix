# programs.mpv.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.mpv;
  inherit (lib) mkIf mkDefault;
  class = "mpv";
in {
  config = mkIf cfg.enable {
    programs.mpv = {
      config = {
        background = mkDefault "color";
        hwdec = "auto";
        hwdec-codecs = "all";
      };
      bindings = {
        h = "seek -10";
        j = "add volume -2";
        k = "add volume 2";
        l = "seek 10";
        "Ctrl+l" = "ab-loop";
      };
    };

    # Treat as media windows by hyprland
    wayland.windowManager.hyprland.settings = {
      windowrule = ["tag +media, class:(${class})"];
    };

    # Make default application for videos
    xdg.mimeApps.defaultApplications = {
      # video
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "video/x-msvideo" = ["mpv.desktop"]; # avi
      "video/x-flv" = ["mpv.desktop"];
      "video/quicktime" = ["mpv.desktop"];
      "video/mpeg" = ["mpv.desktop"];
      "video/*" = ["mpv.desktop"];
      # audio
      "audio/mpeg" = ["mpv.desktop"]; # mp3
      "audio/flac" = ["mpv.desktop"];
      "audio/wav" = ["mpv.desktop"];
      "audio/ogg" = ["mpv.desktop"];
      "audio/aac" = ["mpv.desktop"];
      "audio/opus" = ["mpv.desktop"];
      "audio/*" = ["mpv.desktop"];
    };

    # Do the same in Yazi
    programs.yazi.settings.opener.video = [
      {
        run = ''mpv "$@"'';
        desc = "Play in imv";
        block = false;
        orphan = true;
        for = "unix";
      }
    ];
    programs.yazi.settings.opener.audio = [
      {
        run = ''mpv "$@"'';
        desc = "Play in imv";
        block = false;
        orphan = true;
        for = "unix";
      }
    ];
  };
}
