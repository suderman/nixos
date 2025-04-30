{ config, osConfig, lib, pkgs, ... }: {

  # Lookup uid from flake.users.jon.uid and assign to config.home.uid
  options.home.uid = let 
    inherit (lib) mkOption types;
    inherit (config.home) username;
  in mkOption {
    type = with types; nullOr int;
    default = osConfig.users.users.${username}.uid or null;
  };

  # Calculate offet added to ports (uid - 1000) and assign to config.home.offset
  options.home.offset = let 
    inherit (lib) mkOption types;
    uid = if config.home.uid == null then 1000 else config.home.uid;
  in mkOption {
    type = with types; nullOr int;
    default = if uid >= 1000 then uid - 1000 else 0;
  };

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------
  config = {

    # Add support for ~/.local/bin
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Additional env variables
    home.sessionVariables = {

      # Accept agreements for unfree software (when installing impertively)
      NIXPKGS_ALLOW_UNFREE = "1";

    };

    # xdg-user-dirs are better supported with this
    home.packages = [ pkgs.xdg-user-dirs ];

    # Create home folders (persisted)
    xdg = let home = config.home.homeDirectory; in {
      enable = true;
      userDirs.enable = true;
      cacheHome = "${home}/.cache";
      configHome = "${home}/.config";
      dataHome = "${home}/.local/share";
      stateHome = "${home}/.local/state";
    };

  };

}
