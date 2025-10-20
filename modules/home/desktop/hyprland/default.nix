# osConfig.programs.hyprland.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
in {
  imports =
    [flake.homeModules.desktop.default]
    ++ flake.lib.ls ./.;

  options.wayland.windowManager.hyprland = {
    enablePlugins = lib.mkEnableOption "enablePlugins";
    systemd.target = lib.mkOption {
      type = lib.types.str;
      default = "hyprland-ready.target";
    };
  };

  config = {
    # Automatically enable home-manager module if nixos module is enabled
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.unstable.hyprland;

      systemd = {
        enable = true;
        enableXdgAutostart = true;
        variables = [
          "DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
        ];
        extraCommands = [
          "systemctl --user stop ${cfg.systemd.target}"
          "systemctl --user start ${cfg.systemd.target}"
        ];
      };
    };

    home.shellAliases.hyprland = "Hyprland"; # I'll never remember the H

    # Add target that is enabled by exec-once at the top of the configuration
    systemd.user.targets."${lib.removeSuffix ".target" cfg.systemd.target}".Unit = {
      Description = "Hyprland compositor session after dbus-update-activation-environment";
      Requires = ["hyprland-session.target"];
    };
  };
}
