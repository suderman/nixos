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
  inherit (config.lib.keyd) mkClass;

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
    # Persist configuration in storage
    persist.storage.directories = [".config/GIMP" ".local/share/GIMP"];

    xdg.mimeApps.defaultApplications = {
    };

    # Do the same in Yazi
    programs.yazi.settings.opener.edit-image = [
      {
        run = ''gimp "$@"'';
        desc = "Edit in GIMP";
        block = false;
        orphan = true;
        for = "unix";
      }
    ];
    wayland.windowManager.hyprland.lua.features.gimp = ''
      hl.window_rule({
          name = "gimp-file-dialog-tag",
          match = { class = "file-png|file-jpeg" },
          tag = "+dialog",
      })
      hl.window_rule({
          name = "gimp-dialog-tag",
          match = { class = "gimp", title = "(Open.*|Export.*|Save.*|Preferences.*|Configure.*|Module.*)" },
          tag = "+dialog",
      })
    '';
  };
}
