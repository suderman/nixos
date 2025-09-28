{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkOption types;
in {
  # Convenience option for home scratch directory (persists without snapshots)
  options.home.scratchDirectory = mkOption {
    description = "Path to home scratch directory";
    type = types.str;
    default = "${config.home.homeDirectory}/scratch";
  };

  # Convenience option for home storage directory (persists with snapshots)
  options.home.storageDirectory = mkOption {
    description = "Path to home storage directory";
    type = types.str;
    default = "${config.home.homeDirectory}/storage";
  };

  options.home.desktopDirectory = mkOption {
    type = types.str;
    default = "Desktop";
  };

  options.home.downloadDirectory = mkOption {
    type = types.str;
    default = "Downloads";
  };

  options.home.documentsDirectory = mkOption {
    type = types.str;
    default = "Documents";
  };

  options.home.musicDirectory = mkOption {
    type = types.str;
    default = "Music";
  };

  options.home.picturesDirectory = mkOption {
    type = types.str;
    default = "Pictures";
  };

  options.home.publicShareDirectory = mkOption {
    type = types.str;
    default = "Public";
  };

  options.home.templatesDirectory = mkOption {
    type = types.str;
    default = "Templates";
  };

  options.home.videosDirectory = mkOption {
    type = types.str;
    default = "Videos";
  };

  options.home.developmentDirectory = mkOption {
    type = types.str;
    default = "Developement";
  };

  options.home.gamesDirectory = mkOption {
    type = types.str;
    default = "Games";
  };

  options.home.notesDirectory = mkOption {
    type = types.str;
    default = "Notes";
  };

  options.home.projectsDirectory = mkOption {
    type = types.str;
    default = "Projects";
  };

  config = {
    # xdg-user-dirs are better supported with this
    home.packages = [pkgs.xdg-user-dirs];

    # XDG base directories
    xdg = with config.home; {
      enable = true;
      cacheHome = "${homeDirectory}/.cache"; # XDG_CACHE_HOME
      configHome = "${homeDirectory}/.config"; # XDG_CONFIG_HOME
      dataHome = "${homeDirectory}/.local/share"; # XDG_DATA_HOME
      stateHome = "${homeDirectory}/.local/state"; # XDG_STATE_HOME

      # Default XDG user directories
      userDirs.enable = mkDefault true;
      userDirs.extraConfig = {
        # Standard user dirs
        XDG_DESKTOP_DIR = mkDefault "${homeDirectory}/${desktopDirectory}";
        XDG_DOWNLOAD_DIR = mkDefault "${homeDirectory}/${downloadDirectory}";
        XDG_DOCUMENTS_DIR = mkDefault "${homeDirectory}/${documentsDirectory}";
        XDG_MUSIC_DIR = mkDefault "${homeDirectory}/${musicDirectory}";
        XDG_PICTURES_DIR = mkDefault "${homeDirectory}/${picturesDirectory}";
        XDG_PUBLICSHARE_DIR = mkDefault "${homeDirectory}/${publicShareDirectory}";
        XDG_TEMPLATES_DIR = mkDefault "${homeDirectory}/${templatesDirectory}";
        XDG_VIDEOS_DIR = mkDefault "${homeDirectory}/${videosDirectory}";

        # Custom user dirs
        XDG_DEVELOPMENT_DIR = mkDefault "${homeDirectory}/${developmentDirectory}";
        XDG_GAMES_DIR = mkDefault "${homeDirectory}/${gamesDirectory}";
        XDG_NOTES_DIR = mkDefault "${homeDirectory}/${notesDirectory}";
        XDG_PROJECTS_DIR = mkDefault "${homeDirectory}/${projectsDirectory}";
      };
    };

    persist.scratch.directories = [
      config.home.desktopDirectory
      config.home.downloadDirectory
    ];

    persist.storage.directories = [
      config.home.developmentDirectory
      config.home.documentsDirectory
      config.home.gamesDirectory
      config.home.musicDirectory
      config.home.notesDirectory
      config.home.picturesDirectory
      config.home.projectsDirectory
      config.home.videosDirectory
    ];
  };
}
