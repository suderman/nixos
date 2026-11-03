{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.doctl.enable = lib.mkEnableOption "DigitalOcean CLI";

  config = lib.mkIf config.programs.doctl.enable {
    home.packages = [pkgs.doctl];
    persist.storage.directories = [
      {
        directory = ".config/doctl";
        mode = "0700";
      }
    ];
  };
}
