# Declared for every desktop so feature modules can contribute Lua
# without checking which compositor imported them.
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.wayland.windowManager.hyprland.lua = {
    rounding = mkOption {
      type = types.int;
      default = 10;
      description = "Host-specific window corner radius.";
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
          transform = mkOption {
            type = types.ints.between 0 7;
            default = 0;
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
      description = "Feature-local Lua chunks rendered into ~/.config/hypr/features/*.lua.";
    };
  };
}
