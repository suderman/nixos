# config.programs.dolphin-emu.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.steam;
  inherit (lib) mkIf options;
in {
  options.programs.dolphin-emu.enable = options.mkEnableOption "dolphin-emu";
  config = mkIf cfg.enable {
    home.packages = [pkgs.dolphin-emu];
    persist.storage.directories = [
      ".config/dolphin-emu" # global settings, controller configs, paths
      ".local/share/dolphin-emu" # memory cards, save states, NAND/Wii data
    ];
    persist.scratch.directories = [
      ".cache/dolphin-emu" # shader cache; rebuildable, but avoids stutter
    ];
  };
}
