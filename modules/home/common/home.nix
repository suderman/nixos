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

    home.packages = [ pkgs.xdg-user-dirs ];

    # Create home folders (persisted)
    xdg = let home = config.home.homeDirectory; in {
      enable = true;
      cacheHome = "${home}/.cache";
      configHome = "${home}/.config";
      dataHome = "${home}/.local/share"; # persist
      stateHome = "${home}/.local/state";
      userDirs.enable = true;
      userDirs.createDirectories = true;
      userDirs.desktop = "${home}/Action"; # persist
      userDirs.download = "${home}/Downloads"; # persist
      userDirs.documents = "${home}/Documents"; # persist
      userDirs.music = "${home}/Music"; # persist
      userDirs.pictures = "${home}/Pictures"; # persist
      userDirs.videos = "${home}/Videos"; # persist
      userDirs.publicShare = "${home}/Public"; # persist
    };

  };

}
