{...}: {
  programs.freetube = {
    enable = true;
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

  # tag Freetube windows
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "tag +yt, class:[Ff]reetube"
    ];
  };

  # keyboard shortcuts
  services.keyd.windows = {
    freetube = {
      "super.o" = "C-l"; # location bar
      "super.n" = "C-n"; # new window
      "super.r" = "C-r"; # reload
      "super.[" = "A-left"; # prev tab
      "super.]" = "A-right"; # next tab
      "super.w" = "C-w"; # close tab
    };
  };

  # Persist reboots but skip backups
  persist.scratch.directories = [".config/FreeTube"];
}
