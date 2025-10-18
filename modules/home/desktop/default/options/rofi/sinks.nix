# config.programs.rofi.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.rofi;
  inherit (lib) concatStringsSep mkOption mkIf types;
  sinks = "rofi-toggle -show sinks:rofi-sinks -cycle -theme-str 'window {width: 50%;}'";
in {
  options.programs.rofi = {
    extraSinks = mkOption {
      type = with types; listOf str;
      default = [];
    };
    hiddenSinks = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };

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
    xdg.configFile = {
      "rofi/extra.sinks".text = concatStringsSep "\n" cfg.extraSinks;
      "rofi/hidden.sinks".text = concatStringsSep "\n" cfg.hiddenSinks;
    };
  };
}
