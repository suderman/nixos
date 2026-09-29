{config, ...}: {
  home.directories = rec {
    # Standard user directories
    DOCUMENTS = {
      path = ".local/share/documents";
      persist = "storage";
      sync = false;
      enable = true;
    };
    DOWNLOAD = {
      path = "inbox";
      persist = "scratch";
      sync = false;
      enable = true;
    };
    MUSIC = {
      path = "${MEDIA.path}/music";
      sync = false;
      enable = true;
    };
    PICTURES = {
      path = "${MEDIA.path}/images";
      sync = false;
      enable = true;
    };
    VIDEOS = {
      path = "${MEDIA.path}/videos";
      sync = false;
      enable = true;
    };

    # Standard user directories (disabled)
    DESKTOP.enable = false;
    PUBLICSHARE.enable = false;
    TEMPLATES.enable = false;

    # Custom user directories
    APP = {
      path = "app";
      persist = "storage";
      sync = true;
      enable = true;
    };
    DATA = {
      path = "data";
      persist = "storage";
      sync = false;
      enable = true;
    };
    GAMES = {
      path = "games";
      persist = "storage";
      sync = true;
      syncDevices = ["kit" "cog"];
      enable = true;
    };
    MEDIA = {
      path = "media";
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
    PROFILE = {
      path = "profile";
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
