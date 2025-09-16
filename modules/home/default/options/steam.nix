# osConfig.programs.steam.enable = true;
{
  osConfig,
  lib,
  ...
}: let
  oscfg = osConfig.programs.steam;
  inherit (lib) mkIf;
in {
  config = mkIf oscfg.enable {
    # ".local/share/Steam/userdata" # non-cloud saves
    # ".local/share/Steam/config" # client prefs, library layout
    # ".local/share/Steam/local.vdf" # login info
    persist.scratch.directories = [".local/share/Steam"];
  };
}
