{lib, osConfig, config, ...}: let
  inherit (lib) mkEnableOption mkOption types;
  hostName = osConfig.networking.hostName or config.networking.hostName or "default";
in {
  options.wayland.windowManager.hyprland.lua = {
    enable = mkEnableOption "direct Hyprland Lua configuration";

    host = mkOption {
      type = types.str;
      default = hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = "Logical Hyprland host profile name exposed to Lua. Defaults to the current host name and only needs overriding if a host should reuse a different Hyprland profile.";
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
}
