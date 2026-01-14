# programs.zathura.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.zathura;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;
  class = "org.pwmt.zathura";
in {
  config = mkIf cfg.enable {
    programs.zathura = {
      options = {
        database = "sqlite";
      };
      mappings = {
        f = "navigate next";
        B = "navigate next";
        "<Space>" = "navigate next";
        "]" = "navigate next";
        "<Right>" = "navigate next";

        b = "navigate previous";
        F = "navigate previous";
        "<S-Space>" = "navigate previous";
        "[" = "navigate previous";
        "<Left>" = "navigate previous";

        h = "scroll left";
        j = "scroll down";
        k = "scroll up";
        l = "scroll right";

        "-" = "zoom out";
        "_" = "zoom out";
        "<Up>" = "zoom out";
        "=" = "zoom in";
        "+" = "zoom in";
        "<Down>" = "zoom in";
        "0" = "zoom default";

        r = "rotate rotate-cw";
        R = "rotate rotate-ccw";

        i = "toggle_status_bar";
        o = "file_chooser";
        D = "toggle_page_mode";
      };
    };

    services.keyd.windows."${mkClass class}" = {
      "tab" = "f"; # next
      "shift.tab" = "b"; # previous
      "backslash" = "a";
    };

    # Persist history, bookmarks, last page position
    persist.storage.directories = [".local/share/zathura"];

    # Treat as media windows by hyprland
    wayland.windowManager.hyprland.settings = {
      windowrule = ["tag +media, match:class (${class})"];
    };

    # Make default application for PDFs, PDFs, XPS
    xdg.mimeApps.defaultApplications = {
      "application/pdf" = ["org.pwmt.zathura.desktop"];
      "application/vnd.ms-xpsdocument" = ["org.pwmt.zathura.desktop"];
      "image/vnd.djvu" = ["org.pwmt.zathura.desktop"];
    };

    # Do the same in Yazi
    programs.yazi.settings.opener.pdf = [
      {
        run = ''zathura "$@"'';
        desc = "View in Zathura";
        block = false;
        orphan = true;
        for = "unix";
      }
    ];
  };
}
