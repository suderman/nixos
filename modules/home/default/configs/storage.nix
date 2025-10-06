{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs mapAttrsToList mkDefault mkOption types;

  # List of enabled user directories
  directories = filterAttrs (_name: directory: directory.enable) config.home.directories;
in {
  options.home.directories = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        path = mkOption {
          type = types.str;
          description = "The path of the directory relative to home";
          example = "Downloads";
        };
        persist = mkOption {
          type = types.nullOr (types.enum ["scratch" "storage"]);
          default = null;
          description = ''
            Persistence strategy for this directory:
            - "scratch": persist reboots without snapshots or backups
            - "storage": persist reboots with snapshots and backups
            - null: cleared on reboot
          '';
        };
        sync = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to sync this directory with Syncthing";
        };
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to create this directory";
        };
      };
    });
    default = {};
  };

  config = {
    home = {
      # xdg-user-dirs are better supported with this
      packages = [pkgs.xdg-user-dirs];

      # Make programs use XDG directories whenever supported
      preferXdgDirectories = mkDefault true;

      # Standard user directories
      directories = {
        XDG_DESKTOP_DIR = {
          path = mkDefault "Desktop";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        XDG_DOWNLOAD_DIR = {
          path = mkDefault "Downloads";
          persist = mkDefault null;
          sync = mkDefault false;
          enable = mkDefault true;
        };
        XDG_DOCUMENTS_DIR = {
          path = mkDefault "Documents";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        XDG_MUSIC_DIR = {
          path = mkDefault "Music";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        XDG_PICTURES_DIR = {
          path = mkDefault "Pictures";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        XDG_PUBLICSHARE_DIR = {
          path = mkDefault "Public";
          persist = mkDefault null;
          sync = mkDefault false;
          enable = mkDefault true;
        };
        XDG_TEMPLATES_DIR = {
          path = mkDefault "Templates";
          persist = mkDefault null;
          sync = mkDefault false;
          enable = mkDefault true;
        };
        XDG_VIDEOS_DIR = {
          path = mkDefault "Videos";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
      };
    };

    # XDG base directories
    xdg = {
      enable = true;
      cacheHome = "${config.home.homeDirectory}/.cache"; # XDG_CACHE_HOME
      configHome = "${config.home.homeDirectory}/.config"; # XDG_CONFIG_HOME
      dataHome = "${config.home.homeDirectory}/.local/share"; # XDG_DATA_HOME
      stateHome = "${config.home.homeDirectory}/.local/state"; # XDG_STATE_HOME

      # Default XDG user directories
      userDirs = rec {
        enable = mkDefault true;
        createDirectories = mkDefault true;
        extraConfig = mapAttrs (_: d: "${config.home.homeDirectory}/${d.path}") directories;
        # Ensure these align with extraConfig
        desktop = extraConfig.XDG_DESKTOP_DIR or null;
        documents = extraConfig.XDG_DOCUMENTS_DIR or null;
        download = extraConfig.XDG_DOWNLOAD_DIR or null;
        music = extraConfig.XDG_MUSIC_DIR or null;
        pictures = extraConfig.XDG_PICTURES_DIR or null;
        templates = extraConfig.XDG_TEMPLATES_DIR or null;
        publicShare = extraConfig.XDG_PUBLICSHARE_DIR or null;
        videos = extraConfig.XDG_VIDEOS_DIR or null;
      };
    };

    # Add persisted user directories to list
    persist = {
      scratch.directories = mapAttrsToList (_: d: d.path) (filterAttrs (_: d: d.persist == "scratch") directories);
      storage.directories = mapAttrsToList (_: d: d.path) (filterAttrs (_: d: d.persist == "storage") directories);
    };
  };
}
