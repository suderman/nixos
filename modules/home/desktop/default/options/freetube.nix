# programs.freetube.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.freetube;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    programs.freetube = {
      settings = {
        allowDashAv1Formats = true;
        checkForUpdates = false;
        defaultQuality = "1080";
        baseTheme = "catppuccinMocha";
        defaultTheatreMode = true;
        useSponsorBlock = true;
        useDeArrowTitles = true;
        useDeArrowThumbnails = true;
        hideLabelsSideBar = true;
        hideHeaderLogo = true;
        region = "CA";
      };
    };
    # keyboard shortcuts
    services.keyd.windows = {
      freetube = {
        # "super.n" = "C-n"; # new window
        "super.r" = "C-r"; # reload
        "super.[" = "A-left"; # prev tab
        "super.]" = "A-right"; # next tab
        "super.w" = "C-w"; # close tab
      };
    };

    # Persist reboots but skip backups
    persist.scratch.directories = [".config/FreeTube"];
    wayland.windowManager.hyprland.lua.features.freetube =
      # lua
      ''
        hl.window_rule({
          name = "freetube-tag",
          match = { class = "[Ff]reetube" },
          tag = "+yt",
        })
      '';
  };
}
