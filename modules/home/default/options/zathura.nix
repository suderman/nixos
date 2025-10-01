# programs.zathura.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.zathura;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    programs.zathura = {
      options = {
        database = "sqlite";
      };
      mappings = {
        D = "toggle_page_mode";
      };
    };

    # Persist history, bookmarks, last page position
    persist.storage.directories = [".local/share/zathura"];

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
