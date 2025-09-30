{config, ...}: {
  home.directories = {
    # Standard user directories
    XDG_DESKTOP_DIR = {
      path = "desktop";
      persist = "storage";
      enable = true;
    };
    XDG_DOCUMENTS_DIR = {
      path = "documents";
      persist = "storage";
      enable = true;
    };
    XDG_DOWNLOAD_DIR = {
      path = "downloads";
      persist = "scratch";
      enable = true;
    };
    XDG_MUSIC_DIR = {
      path = "music";
      persist = "storage";
      enable = true;
    };
    XDG_PICTURES_DIR = {
      path = "pictures";
      persist = "storage";
      enable = true;
    };
    XDG_VIDEOS_DIR = {
      path = "movies";
      persist = "storage";
      enable = true;
    };

    # Standard user directories (disabled)
    XDG_PUBLICSHARE_DIR.enable = false;
    XDG_TEMPLATES_DIR.enable = false;

    # Custom user directories
    XDG_GAMES_DIR = {
      path = "games";
      persist = "storage";
      enable = true;
    };
    XDG_NOTES_DIR = {
      path = "notes";
      persist = "storage";
      enable = true;
    };
    XDG_SOURCE_DIR = {
      path = "src";
      persist = "storage";
      enable = true;
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    config.xdg.userDirs.extraConfig.XDG_SOURCE_DIR
  ];

  persist.storage.directories = [];
  persist.storage.files = [];
}
