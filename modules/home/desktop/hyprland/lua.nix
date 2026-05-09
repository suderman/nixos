{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;
  luaCfg = cfg.lua;

  inherit (lib) concatMapStringsSep listToAttrs mkEnableOption mkIf mkOption nameValuePair optionalString types;

  waybarWatcher = pkgs.self.mkScript {
    path = [pkgs.socat pkgs.procps];
    text =
      # bash
      ''
        handle() {
          case $1 in
          workspacev2\>\>*)
            pkill -RTMIN+8 waybar
            ;;
          esac
        }
        socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
      '';
  };

  renderLuaString = value: builtins.toJSON value;

  renderLuaList = values:
    if values == []
    then "{}"
    else "{\n${concatMapStringsSep "\n" (value: "  ${renderLuaString value},") values}\n}";

  renderLuaMonitors = monitors:
    if monitors == []
    then "{}"
    else
      "{\n"
      + concatMapStringsSep "\n" (
        monitor:
          "  { output = ${renderLuaString monitor.output}, mode = ${renderLuaString monitor.mode}, position = ${renderLuaString monitor.position}, scale = ${renderLuaString monitor.scale}${optionalString monitor.disabled ", disabled = true"} },"
      ) monitors
      + "\n}";

  renderLuaAttrs = attrs:
    let
      names = builtins.attrNames attrs;
    in
      if names == []
      then "{}"
      else
        "{\n"
        + concatMapStringsSep "\n" (name: "  ${name} = ${renderLuaString attrs.${name}},") names
        + "\n}";

  featureModule = name: body: ''
    local util = require("lib.util")

    local M = {}

    function M.apply(_, _)
    ${body}
    end

    return M
  '';

  generatedFeatureFiles =
    listToAttrs (map (name: nameValuePair ".config/hypr/features/${name}.lua" {
        text = featureModule name luaCfg.features.${name};
      }) (builtins.attrNames luaCfg.features));

  generatedFeatureList = ''
    return ${renderLuaList (builtins.attrNames luaCfg.features)}
  '';

  generatedFeatures = ''
    return {
      exec_once = ${renderLuaList (
      [
        "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target"
        "${waybarWatcher}"
      ]
      ++ lib.optional cfg.enablePlugins "hyprctl plugin load ${perSystem.hypr-dynamic-cursors.default}/lib/libhypr-dynamic-cursors.so"
    )},
      exec = ${renderLuaList [
        "pkill -RTMIN+8 waybar"
        "chromium --no-startup-window"
        "chromium-agent --no-startup-window"
      ]},
      plugins = {
        dynamic_cursors = {
          enabled = ${if cfg.enablePlugins then "true" else "false"},
          path = ${renderLuaString "${perSystem.hypr-dynamic-cursors.default}/lib/libhypr-dynamic-cursors.so"},
        },
      },
    }
  '';

  generatedHost = ''
    return {
      name = ${renderLuaString luaCfg.host},
      monitors = ${renderLuaMonitors luaCfg.monitors},
      env = ${renderLuaAttrs luaCfg.env},
      exec_once = ${renderLuaList luaCfg.execOnce},
    }
  '';
in {
  options.wayland.windowManager.hyprland.lua = {
    enable = mkEnableOption "direct Hyprland Lua configuration";

    host = mkOption {
      type = types.str;
      default = "default";
      description = "Logical Hyprland host profile name exposed to Lua.";
    };

    execOnce = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Host-specific startup commands executed once by hyprland.lua.";
    };

    env = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Host-specific environment variables exported from hyprland.lua.";
    };

    monitors = mkOption {
      default = [];
      description = "Host-specific monitor declarations for hyprland.lua.";
      type = types.listOf (types.submodule {
        options = {
          output = mkOption {
            type = types.str;
          };
          mode = mkOption {
            type = types.str;
            default = "preferred";
          };
          position = mkOption {
            type = types.str;
            default = "0x0";
          };
          scale = mkOption {
            type = types.str;
            default = "1";
          };
          disabled = mkOption {
            type = types.bool;
            default = false;
          };
        };
      });
    };

    features = mkOption {
      type = types.attrsOf types.lines;
      default = {};
      description = "Feature-local Lua bodies rendered into ~/.config/hypr/features/*.lua.";
    };
  };

  config = mkIf luaCfg.enable {
    home.file = {
      ".config/hypr/hyprland.lua".source = ./lua/hyprland.lua;
      ".config/hypr/lib/util.lua".source = ./lua/lib/util.lua;
      ".config/hypr/conf/session.lua".source = ./lua/conf/session.lua;
      ".config/hypr/conf/look.lua".source = ./lua/conf/look.lua;
      ".config/hypr/conf/input.lua".source = ./lua/conf/input.lua;
      ".config/hypr/conf/layouts.lua".source = ./lua/conf/layouts.lua;
      ".config/hypr/conf/group.lua".source = ./lua/conf/group.lua;
      ".config/hypr/binds/main.lua".source = ./lua/binds/main.lua;
      ".config/hypr/rules/windows.lua".source = ./lua/rules/windows.lua;
      ".config/hypr/generated/features.lua".text = generatedFeatures;
      ".config/hypr/generated/host.lua".text = generatedHost;
      ".config/hypr/generated/feature-list.lua".text = generatedFeatureList;
    } // generatedFeatureFiles;

    home.localStorePath = [
      ".config/hypr/local/init.lua"
    ];

    persist.storage.directories = [".config/hypr/local"];
    tmpfiles.files = [".config/hypr/local/init.lua"];
  };
}
