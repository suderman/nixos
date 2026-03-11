# config.programs.ryubing.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.ryubing;
  inherit (lib) mkIf options;
in {
  options.programs.ryubing.enable = options.mkEnableOption "ryubing";
  config = mkIf cfg.enable {
    persist.storage.directories = [
      ".local/share/ryubing" # main data directory
      ".config/ryubing" # controller mappings, ui prefs
    ];
    persist.scratch.directories = [
      ".cache/ryubing" # rebuildable
    ];
    home.packages = [pkgs.unstable.ryubing];
  };
}
