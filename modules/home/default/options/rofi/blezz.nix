# config.programs.rofi.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
  blezz = "rofi-toggle -show blezz -auto-select -matching normal -theme-str 'window {width: 30%;}'";
in {
  config = lib.mkIf cfg.enable {
    programs.rofi.plugins = [pkgs.unstable.rofi-blezz];
    wayland.windowManager.hyprland.settings = {
      bindr = [
        "super, Super_R, exec, ${blezz}" # Right Super is blezz
      ];
      bind = [
        "super+alt, space, exec, ${blezz}"
      ];
    };
  };
}
