{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.quickshell;
  inherit (lib) concatStringsSep mapAttrsToList mkIf mkOption types;

  shell = pkgs.writeText "quickshell-hyprland-shell.qml" ''
    import Quickshell
    import QtQuick

    Scope {
      id: shell

      ${concatStringsSep "\n\n" cfg.components}
    }
  '';

  configDir = pkgs.runCommand "quickshell-${cfg.configName}-config" {} (
    ''
      mkdir -p "$out"
      install -m 0444 ${shell} "$out/shell.qml"
    ''
    + concatStringsSep "\n" (mapAttrsToList (name: source: ''
        install -D -m 0444 ${source} "$out/${name}"
      '')
      cfg.files)
  );
in {
  options.wayland.windowManager.hyprland.quickshell = {
    enable = lib.mkEnableOption "shared Quickshell config for Hyprland widgets";

    package = mkOption {
      type = types.package;
      default = pkgs.quickshell;
      description = "Quickshell package to use for the shared Hyprland shell.";
    };

    configName = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Named Quickshell config managed by Home Manager.";
    };

    components = mkOption {
      type = types.listOf types.lines;
      default = [];
      description = "Top-level QML component instances inserted into shell.qml.";
    };

    files = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Files copied into the generated Quickshell config directory.";
    };
  };

  config = mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      package = cfg.package;
      activeConfig = cfg.configName;
      configs."${cfg.configName}" = configDir;
      systemd = {
        enable = true;
        target = config.wayland.systemd.target;
      };
    };

    # Quickshell reads QML at startup and the upstream Home Manager unit only
    # references the config name. Include the generated path in the unit so
    # sd-switch restarts Quickshell when declarative QML changes.
    systemd.user.services.quickshell.Service.Environment = [
      "QUICKSHELL_CONFIG_GENERATION=${configDir}"
    ];

    wayland.windowManager.hyprland.lua.features.quickshell =
      # lua
      ''
        hl.layer_rule({
          name = "quickshell-overlay-blur",
          match = { namespace = "^quickshell-" },
          blur = true,
          animation = "fade",
        })
      '';
  };
}
