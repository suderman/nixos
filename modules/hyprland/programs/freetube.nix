{ config, lib, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    programs.freetube = {
      enable = true;
      settings = {

        allowDashAv1Formats  = true;
        checkForUpdates      = false;
        defaultQuality       = "1080";
        baseTheme            = "catppuccinMocha";
        defaultTheatreMode   = true;
        useSponsorBlock      = true;
        useDeArrowTitles     = true;
        useDeArrowThumbnails = true;
        hideLabelsSideBar    = true;
        hideHeaderLogo       = true;
        region               = "CA";

      };
    };

    # tag Freetube windows
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "tag +yt, class:[Ff]reetube"
      ];
    };

    # keyboard shortcuts
    services.keyd.applications = {
      freetube = {
        "alt.l" = "C-l"; # location bar
        "super.o" = "C-l"; # location bar
        "super.n" = "C-n"; # new window
      };
    };

  };

}
