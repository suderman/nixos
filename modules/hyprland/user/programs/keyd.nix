{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkShellScript;

in {

  config = mkIf cfg.enable {

    services.keyd = {
      enable = true;
      systemdTarget = cfg.systemd.target;
      windows = {
        "*" = {

          # Map meta a/z to ctrl a/z
          "super.a" = "C-a";
          "super.z" = "C-z";

          # Quick access to escape key
          "j+k" = "esc";

          # Media keys
          "alt.a" = "volumedown";
          "alt.s" = "volumeup";
          "alt.d" = "mute";
          # "alt.space" = "playpause";

        };
      };
      layers = {};

    };

  };
}
