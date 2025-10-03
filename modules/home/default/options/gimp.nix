# -- custom module --
# programs.gimp.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.gimp;
  inherit (lib) mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "gimp-3.0";
in {
  options.programs.gimp = {
    enable = lib.options.mkEnableOption "gimp";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.gimp3-with-plugins];

    xdg.desktopEntries."${class}" = {
      name = "GIMP";
      icon = "org.gimp.GIMP";
      noDisplay = true;
    };

    services.keyd.windows."${mkClass class}" = {};

    # Tag export windows as floating dialogs
    wayland.windowManager.hyprland.settings.windowrule = [
      "tag +dialog, class:(file-png|file-jpeg)"
      "tag +dialog, class:gimp, title:(Open.*|Export.*|Save.*|Preferences.*|Configure.*|Module.*)"
    ];

    # Persist configuration in storage
    persist.storage.directories = [".config/GIMP" ".local/share/GIMP"];
  };
}
