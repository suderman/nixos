{ config, osConfig, lib, pkgs, this, ... }: {

  # Lookup uid from configurations/all/uids.nix and assign to config.home.uid
  options.home.uid = let 
    inherit (lib) hasAttr mkOption types;
    inherit (config.home) username;
    inherit (osConfig.ids) uids;
  in mkOption {
    type = with types; nullOr int;
    default = if hasAttr username uids then uids."${username}" else null;
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


    # Attempts to make Wayland work. Was needed at the time, probably not anymore. Need to clean this up.
    home.sessionVariables = {

      # MOZ_ENABLE_WAYLAND = "1";
      # MOZ_USE_XINPUT2 = "1";
      # GDK_BACKEND = "wayland";
      # QT_QPA_PLATFORM = "wayland";
      # QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      # NIXOS_OZONE_WL = "1";
      # WAYLAND_DISPLAY = "wayland-0";
      # QT_WAYLAND_FORCE_DPI = "physical";
      # QT_SCALE_FACTOR = "1.25";
      # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # SAL_USE_VCLPLUGIN = "gtk3";

      # Accept agreements for unfree software (when installing impertively)
      NIXPKGS_ALLOW_UNFREE = "1";

    };

  };

}
