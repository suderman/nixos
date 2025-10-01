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
    programs.yazi = {
      options = {};
      mappings = {
        "" = "navigate next";
        D = "toggle_page_mode";
        "[fullscreen] " = "zoom in";
      };
    };
    # Persist history, bookmarks, last page position
    persist.storage.directories = [".local/share/zathura"];
  };
}
