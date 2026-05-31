{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs mapAttrsToList mkDefault mkOption types;

  # List of enabled user directories
  directories = filterAttrs (_name: directory: directory.enable) config.home.directories;
  dirPaths = mapAttrs (_: d: "${config.home.homeDirectory}/${d.path}") directories;
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
        DESKTOP = {
          path = mkDefault "Desktop";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        DOWNLOAD = {
          path = mkDefault "Downloads";
          persist = mkDefault null;
          sync = mkDefault false;
          enable = mkDefault true;
        };
        DOCUMENTS = {
          path = mkDefault "Documents";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        MUSIC = {
          path = mkDefault "Music";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        PICTURES = {
          path = mkDefault "Pictures";
          persist = mkDefault null;
          sync = mkDefault true;
          enable = mkDefault true;
        };
        PUBLICSHARE = {
          path = mkDefault "Public";
          persist = mkDefault null;
          sync = mkDefault false;
          enable = mkDefault true;
        };
        TEMPLATES = {
          path = mkDefault "Templates";
          persist = mkDefault null;
          sync = mkDefault false;
          enable = mkDefault true;
        };
        VIDEOS = {
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
        setSessionVariables = mkDefault true;
        createDirectories = mkDefault true;
        extraConfig = dirPaths;
        # Ensure these align with extraConfig
        desktop = dirPaths.DESKTOP or null;
        documents = dirPaths.DOCUMENTS or null;
        download = dirPaths.DOWNLOAD or null;
        music = dirPaths.MUSIC or null;
        pictures = dirPaths.PICTURES or null;
        templates = dirPaths.TEMPLATES or null;
        publicShare = dirPaths.PUBLICSHARE or null;
        videos = dirPaths.VIDEOS or null;
      };
    };

    # Add persisted user directories to list
    persist = {
      scratch.directories = mapAttrsToList (_: d: d.path) (filterAttrs (_: d: d.persist == "scratch") directories);
      storage.directories = mapAttrsToList (_: d: d.path) (filterAttrs (_: d: d.persist == "storage") directories);
    };
  };
}
