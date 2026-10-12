{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.dynamicCursors;
in {
  options.wayland.windowManager.hyprland.dynamicCursors.enable =
    lib.mkEnableOption "the hypr-dynamic-cursors plugin";

  config = {
    home.packages = [pkgs.hyprcursor];
    # Renders as hl.plugin.load(...) ahead of the shared Lua config.
    wayland.windowManager.hyprland.settings."plugin.load" =
      lib.mkIf cfg.enable "${perSystem.hypr-dynamic-cursors.default}/lib/libhypr-dynamic-cursors.so";
  };
}
