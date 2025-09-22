{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
in {
  # Lookup uid from flake.users.jon.uid and assign to config.home.uid
  options.home.uid = mkOption {
    type = with types; nullOr int;
    default = osConfig.users.users.${config.home.username}.uid or null;
  };

  # Calculate offet added to ports (uid - 1000) and assign to config.home.offset
  options.home.offset = mkOption {
    type = with types; nullOr int;
    default = let
      uid =
        if config.home.uid == null
        then 1000
        else config.home.uid;
    in
      if uid >= 1000
      then uid - 1000
      else 0;
  };

  # Convenience option for home storage directory (persists with snapshots)
  options.home.storageDirectory = mkOption {
    description = "Path to home storage directory";
    type = types.str;
    default = "${config.home.homeDirectory}/storage";
  };

  # Convenience option for home scratch directory (persists without snapshots)
  options.home.scratchDirectory = mkOption {
    description = "Path to home scratch directory";
    type = types.str;
    default = "${config.home.homeDirectory}/scratch";
  };

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------
  config = {
    # Add support for ~/.local/bin
    home.sessionPath = ["$HOME/.local/bin"];

    # Additional env variables
    home.sessionVariables = {
      # Accept agreements for unfree software (when installing impertively)
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    # xdg-user-dirs are better supported with this
    home.packages = [pkgs.xdg-user-dirs];

    # Create home folders (persisted)
    xdg = with config.home; {
      enable = true;
      userDirs.enable = true;
      cacheHome = "${homeDirectory}/.cache";
      configHome = "${homeDirectory}/.config";
      dataHome = "${homeDirectory}/.local/share";
      stateHome = "${homeDirectory}/.local/state";
    };
  };
}
