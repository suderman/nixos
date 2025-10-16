# config.programs.rofi.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
  calc = "rofi-toggle -show calc -modi calc -no-show-match -no-sort -no-history -calc-command \"echo -n '{result}' | wl-copy\" -theme-str 'window {width: 25%;}'";
in {
  config = lib.mkIf cfg.enable {
    programs.rofi.plugins = [pkgs.unstable.rofi-calc];
    wayland.windowManager.hyprland.settings.bind = [
      "super+alt, c, exec, ${calc}"
      "alt+ctrl, insert, exec, ${calc}"
    ];
  };
}
