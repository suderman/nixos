{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    services.keyd = {
      enable = true;
      systemdTarget = cfg.systemd.target;
      applications = {

        # Map meta a/z to ctrl a/z
        "*" = {
          "meta.a" = "C-a";
          "meta.z" = "C-z";
        };

      };

    };

  };
}
