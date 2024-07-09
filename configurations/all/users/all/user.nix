{ config, osConfig, lib, pkgs, this, ... }: {

  options.home.uid = let 
    inherit (lib) hasAttr mkOption types;
    inherit (config.home) username;
    inherit (osConfig.ids) uids;
  in mkOption {
    type = with lib.types; nullOr int;
    default = if hasAttr username uids then uids."${username}" else null;
  };

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------
  config = {

    # Add support for ~/.local/bin
    home.sessionPath = [ "$HOME/.local/bin" ];


    # Attempts to make Wayland work. Was needed at the time, probably not anymore. Need to clean this up.
    home.sessionVariables = {

      # NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      # WAYLAND_DISPLAY = "wayland-0";
      # QT_WAYLAND_FORCE_DPI = "physical";
      # QT_SCALE_FACTOR = "1.25";
      # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # SAL_USE_VCLPLUGIN = "gtk3";

    };

  };

}
