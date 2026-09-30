{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.keyd;
  inherit (config.lib.keyd) expandHomeRowModifierRules;
  expandedWindows = expandHomeRowModifierRules cfg.windows;
  expandedLayers = expandHomeRowModifierRules cfg.layers;
in {
  services.keyd = {
    enable = true;
    systemdTarget = config.wayland.systemd.target;
    # Lua owns window and layer mappings. A second mapper would reset them.
    mapper.enable = lib.mkDefault false;
    windows = {
      "*" = {
        # Map meta a/z to ctrl a/z
        "super.a" = "C-a";
        "super.z" = "C-z";

        # Quick access to escape key
        # "j+k" = "esc";

        # # Media keys
        # "alt.a" = "volumedown";
        # "alt.s" = "volumeup";
        # "alt.d" = "mute";
        # "alt.space" = "playpause";
      };
    };
    layers = {};
  };

  wayland.windowManager.hyprland.lua.features.keyd = let
    inherit (lib) getExe';
    toLua = lib.generators.toLua {};
    toLuaRules = rules:
      toLua (lib.mapAttrsToList (section: bindings: {inherit section bindings;}) rules);
  in
    # lua
    ''
      require("lib.keyd").apply(
        ${toLua (getExe' pkgs.keyd "keyd")},
        ${toLuaRules expandedWindows},
        ${toLuaRules expandedLayers}
      )
    '';
}
