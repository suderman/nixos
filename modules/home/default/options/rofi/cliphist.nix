# config.programs.rofi.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.rofi;
  clips = "rofi-toggle -show clips:rofi-cliphist -show-icons";
in {
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.bind = [
      "super+alt, v, exec, ${clips}"
      "alt+shift, insert, exec, ${clips}"
    ];
    services.cliphist = {
      enable = true;
      allowImages = true;
      extraOptions = [
        "-max-dedupe-search"
        "10"
        "-max-items"
        "500"
      ];
    };

    # Persist clipboard history database
    persist.storage.directories = [".cache/cliphist"];
  };
}
