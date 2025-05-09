{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    programs.freetube = {
      enable = true;

      # package' = pkgs.writeShellScriptBin "freetube" ''
      #   exec ${pkgs.freetube}/bin/freetube --enable-features=WaylandLinuxDrmSyncobj "$@"
      # '';

      # package = pkgs.symlinkJoin {
      #   name = "freetube";
      #   paths = [ pkgs.freetube ];
      #   buildInputs = [ pkgs.makeWrapper ];
      #   postBuild = ''
      #     wrapProgram $out/bin/freetube --add-flags "--enable-features=WaylandLinuxDrmSyncobj"
      #   '';
      # };

      package = lib.wrapWithFlags {
        package = pkgs.freetube;
        flags = [ "--enable-features=WaylandLinuxDrmSyncobj" ];
      };



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

  };

}
