{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
in {
  wayland.windowManager.hyprland = {
    plugins = with pkgs.unstable.hyprlandPlugins;
      lib.mkIf cfg.enablePlugins [
        hypr-dynamic-cursors
      ];
  };
  home.packages = [pkgs.hyprcursor];
}
