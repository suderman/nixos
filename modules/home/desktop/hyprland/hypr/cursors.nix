{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
in {
  wayland.windowManager.hyprland = lib.mkIf cfg.enablePlugins {
    plugins = [pkgs.unstable.hyprlandPlugins.hypr-dynamic-cursors];
    settings = {
      "plugin:dynamic-cursors" = {
        ignore_warps = false;
      };
    };
  };
  home.packages = [pkgs.hyprcursor];
}
