# programs.cachix.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.cachix;
  inherit (lib) mkIf mkEnableOption;
in {
  options.programs.cachix.enable = mkEnableOption "cachix";
  config = mkIf cfg.enable {
    persist.storage.directories = [".config/cachix"];
    home.packages = [pkgs.cachix];
  };
}
