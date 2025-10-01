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

    # Make default application for PDF files
    xdg.mimeApps.defaultApplications = {
      "application/pdf" = ["org.pwmt.zathura.desktop"];
    };
  };
}
