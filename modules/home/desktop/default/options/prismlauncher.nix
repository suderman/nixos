# config.programs.prismlauncher.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.prismlauncher;
in {
  config = lib.mkIf cfg.enable {
    persist.storage.directories = [".local/share/PrismLauncher"];
  };
}
