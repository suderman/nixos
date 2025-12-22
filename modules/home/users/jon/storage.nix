{config, ...}: {
  home.directories = {
    # Standard user directories
    XDG_DESKTOP_DIR = {
      path = "Desktop";
      persist = "storage";
      sync = true;
      enable = true;
    };
    XDG_DOCUMENTS_DIR = {
      path = "Documents";
      persist = "storage";
      sync = true;
      enable = true;
    };
    XDG_DOWNLOAD_DIR = {
      path = "Downloads";
      persist = "scratch";
      sync = false;
      enable = true;
    };
    XDG_MUSIC_DIR = {
      path = "Music";
      persist = "storage";
      sync = true;
      enable = true;
    };
    XDG_PICTURES_DIR = {
      path = "Pictures";
      persist = "storage";
      sync = true;
      enable = true;
    };
    XDG_VIDEOS_DIR = {
      path = "Movies";
      persist = "storage";
      sync = true;
      enable = true;
    };

    # Standard user directories (disabled)
    XDG_PUBLICSHARE_DIR.enable = false;
    XDG_TEMPLATES_DIR.enable = false;

    # Custom user directories
    XDG_GAMES_DIR = {
      path = "Games";
      persist = "storage";
      sync = true;
      enable = true;
    };
    XDG_NOTES_DIR = {
      path = "Notes";
      persist = "storage";
      sync = true;
      enable = true;
    };
    XDG_SOURCE_DIR = {
      path = "src";
      persist = "storage";
      sync = false;
      enable = true;
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    config.xdg.userDirs.extraConfig.XDG_SOURCE_DIR
  ];

  # Known device ids to auomatically setup in syncthing
  services.syncthing.deviceIds = {
    kit = "ARS5AY4-HVAKVHE-5IIYPX5-DZORQBR-UHYYQIQ-ON7JMUI-2PPI5IS-EW3IKAZ";
    cog = "PPAG274-GPYIMXP-5CY62WF-B4QNQCP-5KWIT3Y-RG6OCJG-PRQDBP3-HW5VBQY";
    phone = "U3OH2WI-YRTLO2A-UNNTEPG-QSGAAQH-VNEEQJK-A6TTVHP-KM7KX7L-Q3M5KQV";
  };

  persist.storage.directories = [];
  persist.storage.files = [];
}
