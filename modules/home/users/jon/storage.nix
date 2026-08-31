{config, ...}: {
  home.directories = {
    # Standard user directories
    DESKTOP = {
      path = "desktop";
      persist = "storage";
      sync = true;
      enable = true;
    };
    DOCUMENTS = {
      path = "documents";
      persist = "storage";
      sync = true;
      enable = true;
    };
    DOWNLOAD = {
      path = "downloads";
      persist = "scratch";
      sync = false;
      enable = true;
    };
    MUSIC = {
      path = "music";
      persist = "storage";
      sync = true;
      enable = true;
    };
    PICTURES = {
      path = "pictures";
      persist = "storage";
      sync = true;
      enable = true;
    };
    PUBLICSHARE = {
      path = "public";
      persist = "storage";
      sync = true;
      enable = true;
    };
    VIDEOS = {
      path = "movies";
      persist = "storage";
      sync = true;
      enable = true;
    };

    # Standard user directories (disabled)
    TEMPLATES.enable = false;

    # Custom user directories
    BIN = {
      path = "bin";
      persist = "storage";
      sync = true;
      syncDevices = ["kit" "cog"];
      enable = true;
    };
    ORG = {
      path = "org";
      persist = "storage";
      sync = true;
      enable = true;
    };
    NOTES.enable = false;
    GAMES = {
      path = "games";
      persist = "storage";
      sync = true;
      syncDevices = ["kit" "cog"];
      enable = true;
    };
    SOURCE = {
      path = "src";
      persist = "storage";
      sync = false;
      enable = true;
    };
    PROJECTS = {
      path = "projects";
      persist = "storage";
      sync = true;
      syncDevices = ["kit" "cog"];
      enable = true;
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    "${config.home.homeDirectory}/${config.home.directories.SOURCE.path}"
  ];

  # Known device ids to auomatically setup in syncthing
  services.syncthing.deviceIds = {
    kit = "ARS5AY4-HVAKVHE-5IIYPX5-DZORQBR-UHYYQIQ-ON7JMUI-2PPI5IS-EW3IKAZ";
    cog = "PPAG274-GPYIMXP-5CY62WF-B4QNQCP-5KWIT3Y-RG6OCJG-PRQDBP3-HW5VBQY";
    gem = "U3OH2WI-YRTLO2A-UNNTEPG-QSGAAQH-VNEEQJK-A6TTVHP-KM7KX7L-Q3M5KQV";
  };

  persist.storage.directories = [];
  persist.storage.files = [];
}
