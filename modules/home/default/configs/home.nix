{
  config,
  osConfig,
  lib,
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

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------
  config = {
    # Add support for ~/.local/bin
    home.sessionPath = ["$HOME/.local/bin"];

    # Additional env variables
    home.sessionVariables = {
      # Accept agreements for unfree software (when installing imperatively)
      NIXPKGS_ALLOW_UNFREE = "1";
    };
  };
}
