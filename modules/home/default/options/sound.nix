{
  config,
  lib,
  ...
}: let
  cfg = config.sound;
in {
  options.sound = {
    hiddenSinks = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "List of PulseAudio/PipeWire sink names to hide from menus.";
    };
    extraSinks = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "List of sinks to always show, even if disconnected (e.g. Bluetooth devices).";
    };
  };
  config.xdg.configFile = {
    "pulse/extra-sinks".text = lib.concatStringsSep "\n" cfg.extraSinks;
    "pulse/hidden-sinks".text = lib.concatStringsSep "\n" cfg.hiddenSinks;
  };
}
