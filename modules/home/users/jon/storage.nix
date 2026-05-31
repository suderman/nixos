{config, ...}: {
  home.directories = {
    # Standard user directories
    DESKTOP = {
      path = "Desktop";
      persist = "storage";
      sync = true;
      enable = true;
    };
    DOCUMENTS = {
      path = "Documents";
      persist = "storage";
      sync = true;
      enable = true;
    };
    DOWNLOAD = {
      path = "Downloads";
      persist = "scratch";
      sync = false;
      enable = true;
    };
    MUSIC = {
      path = "Music";
      persist = "storage";
      sync = true;
      enable = true;
    };
    PICTURES = {
      path = "Pictures";
      persist = "storage";
      sync = true;
      enable = true;
    };
    PUBLICSHARE = {
      path = "Public";
      persist = "storage";
      sync = true;
      enable = true;
    };
    VIDEOS = {
      path = "Movies";
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
      enable = true;
    };
    ORG = {
      path = "org";
      persist = "storage";
      sync = true;
      enable = true;
    };
    NOTES = {
      path = "notes";
      persist = "storage";
      sync = true;
      enable = true;
    };
    GAMES = {
      path = "games";
      persist = "storage";
      sync = true;
      enable = true;
    };
    SOURCE = {
      path = "src";
      persist = "storage";
      sync = false;
      enable = true;
    };
    WORKSPACE = {
      path = "workspace";
      persist = "storage";
      sync = true;
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
