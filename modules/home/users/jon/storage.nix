{config, ...}: {
  home = {
    desktopDirectory = "action"; # scratch
    developmentDirectory = "src";
    documentsDirectory = "documents";
    downloadDirectory = "downloads"; # scratch
    gamesDirectory = "games";
    musicDirectory = "music";
    notesDirectory = "notes";
    picturesDirectory = "pictures";
    projectsDirectory = "projects";
    videosDirectory = "movies";
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    config.xdg.userDirs.extraConfig.XDG_DEVELOPMENT_DIR
  ];

  persist.storage.directories = [];
  persist.storage.files = [];
}
