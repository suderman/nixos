# config.programs.rofi.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.rofi;
  inherit (lib) mkIf;
  sinks = "rofi-toggle -show sinks:rofi-sinks -cycle -theme-str 'window {width: 50%;}'";
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      bind = [
        ", XF86AudioMedia, exec, ${sinks}"
      ];
      bindsn = [
        "super_l, a&s, exec, ${sinks}"
        "super_r, a&s, exec, ${sinks}"
      ];
    };
  };
}
