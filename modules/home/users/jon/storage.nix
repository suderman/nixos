{config, ...}: {
  xdg.userDirs = with config.home; {
    documents = "${storageDirectory}/docs"; # XDG_DOCUMENTS_DIR
    music = "${storageDirectory}/music"; # XDG_MUSIC_DIR
    pictures = "${storageDirectory}/pics"; # XDG_PICTURES_DIR
    videos = "${storageDirectory}/vids"; # XDG_VIDEOS_DIR
    publicShare = "${storageDirectory}/action"; # XDG_PUBLICSHARE_DIR
    extraConfig = {
      XDG_AUDIO_DIR = "${storageDirectory}/podcasts";
      XDG_BOOKS_DIR = "${storageDirectory}/books";
      XDG_DEVELOPMENT_DIR = "${storageDirectory}/src";
      XDG_GAMES_DIR = "${storageDirectory}/games";
      XDG_LIBRARY_DIR = "${storageDirectory}/lib";
      XDG_NOTES_DIR = "${storageDirectory}/notes";
      XDG_PROJECTS_DIR = "${storageDirectory}/work";
      XDG_RECORDS_DIR = "${storageDirectory}/papertrail";
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    config.xdg.userDirs.extraConfig.XDG_DEVELOPMENT_DIR
  ];

  persist.storage.directories = [];
  persist.storage.files = [];
}
