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
      userDirs = {
        enable = mkDefault true;
        download = mkDefault scratchDirectory; # XDG_DOWNLOAD_DIR
        desktop = mkDefault storageDirectory; # XDG_DESKTOP_DIR
        documents = mkDefault "${storageDirectory}/Documents"; # XDG_DOCUMENTS_DIR
        music = mkDefault "${storageDirectory}/Music"; # XDG_MUSIC_DIR
        pictures = mkDefault "${storageDirectory}/Pictures"; # XDG_PICTURES_DIR
        publicShare = mkDefault "${storageDirectory}/Share"; # XDG_PUBLICSHARE_DIR
        templates = mkDefault "${storageDirectory}/Templates"; # XDG_TEMPLATES_DIR
        videos = mkDefault "${storageDirectory}/Movies"; # XDG_VIDEOS_DIR

        # Custom XDG user directories
        extraConfig = {
          XDG_DEVELOPMENT_DIR = mkDefault "${storageDirectory}/Development";
          XDG_GAMES_DIR = mkDefault "${storageDirectory}/Games";
          XDG_NOTES_DIR = mkDefault "${storageDirectory}/Notes";
          XDG_AUDIO_DIR = mkDefault "${storageDirectory}/Audio";
          XDG_BOOKS_DIR = mkDefault "${storageDirectory}/Books";
          XDG_PROJECTS_DIR = mkDefault "${storageDirectory}/Projects";
          XDG_LIBRARY_DIR = mkDefault "${storageDirectory}/Library";
          XDG_RECORDS_DIR = mkDefault "${storageDirectory}/Records";
        };
      };
    };
  };
}
