{ config, lib, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      # WAYLAND_DISPLAY = "wayland-0";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      # QT_WAYLAND_FORCE_DPI = "physical";
      # QT_SCALE_FACTOR = "1.25";
      # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      # SAL_USE_VCLPLUGIN = "gtk3";
    };

  };

}
