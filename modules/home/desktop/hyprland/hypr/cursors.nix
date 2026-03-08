{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
in {
  wayland.windowManager.hyprland = lib.mkIf cfg.enablePlugins {
    plugins = [perSystem.hypr-dynamic-cursors.default];
    settings = {
      "plugin:dynamic-cursors" = {
        ignore_warps = false;
      };
    };
  };
  home.packages = [pkgs.hyprcursor];
}
