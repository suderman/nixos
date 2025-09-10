{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.shotcut;
  inherit (lib) mkIf;
in {
  options.programs.shotcut = {
    enable = lib.options.mkEnableOption "Shotcut";
  };
  config = mkIf cfg.enable {
    home.packages = [pkgs.shotcut pkgs.ffmpeg];
    persist.storage.directories = [".config/Meltytech" ".local/share/Meltytech"];
  };
}
