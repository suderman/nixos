{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland.quickshell;
  inherit (lib) concatStringsSep mapAttrsToList mkIf mkOption types;
  appearance = config.programs.desktop-theme;
  staticPalette = pkgs.writeText "quickshell-static-palette.json" (builtins.toJSON (lib.genAttrs
    (map (n: "base${n}") ["00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B" "0C" "0D" "0E" "0F"])
    (n: "#${config.lib.stylix.colors.${n}}")));
  theme = pkgs.replaceVars ./Theme.qml {
    DYNAMIC = lib.boolToString appearance.enable;
    DEFAULT_MODE = builtins.toJSON appearance.defaultMode;
    MODE_PATH =
      if appearance.enable
      then ''(Quickshell.env("XDG_STATE_HOME") || ${builtins.toJSON config.xdg.stateHome}) + "/desktop-theme/mode"''
      else ''""'';
    PALETTE_PATH =
      if appearance.enable
      then ''${builtins.toJSON (toString appearance.assets)} + "/" + root.mode + "/palette.json"''
      else builtins.toJSON (toString staticPalette);
  };

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
    wayland.windowManager.hyprland.quickshell.files."Theme.qml" = theme;
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
