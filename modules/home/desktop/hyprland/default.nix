{
  lib,
  pkgs,
  flake,
  ...
}: {
  imports =
    [flake.homeModules.desktop.default]
    ++ flake.lib.ls ./.;

  options.wayland.windowManager.hyprland = {
    enablePlugins = lib.mkEnableOption "enablePlugins";
  };

  config = {
    wayland = {
      windowManager.hyprland = {
        enable = true;
        package = pkgs.unstable.hyprland;
        systemd.enable = true;
      };
      systemd.target = "hyprland-session.target";
    };

    # Ensure portals and other systemd user services are running
    # https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
    home.packages = [
      (
        pkgs.self.mkScript {
          path = [pkgs.systemd];
          name = "bounce";
          text = let
            restart = name: "sleep 1 && systemctl --user stop ${name} && systemctl --user start ${name}";
          in
            lib.concatStringsSep "\n" [
              (restart "xdg-desktop-portal-hyprland")
              (restart "xdg-desktop-portal-gtk")
              (restart "xdg-desktop-portal")
              (restart "hyprland-session.target")
            ];
        }
      )
    ];
  };
}
