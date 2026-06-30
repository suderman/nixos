# programs.libreoffice.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.libreoffice;
  inherit (lib) mkIf mkOption options types;
in {
  options.programs.libreoffice = {
    enable = options.mkEnableOption "LibreOffice";
    package = mkOption {
      type = types.package;
      default = pkgs.libreoffice;
      description = "LibreOffice package to install.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    # Persist wizard flag and UI settings across reboots (impermanence).
    # ~/.config/libreoffice/4/user/registrymodifications.xcu holds first-run
    # state; without persistence the wizard reappears after root is wiped.
    persist.scratch.directories = [".config/libreoffice"];
  };
}
