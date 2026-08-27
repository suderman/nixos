# programs.buzz.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.buzz;
in {
  options.programs.buzz.enable = lib.mkEnableOption "Buzz desktop client";

  config = lib.mkIf cfg.enable {
    home.packages = [perSystem.buzz.buzz-desktop];
    persist.storage.directories = [".local/share/xyz.block.buzz.app"];
    persist.scratch.directories = [".cache/buzz"];
  };
}
