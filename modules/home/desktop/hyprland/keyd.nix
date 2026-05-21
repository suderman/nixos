{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.keyd;
in {
  services.keyd = {
    enable = true;
    systemdTarget = config.wayland.systemd.target;
    mapper.enable = lib.mkDefault false;
    windows = {
      "*" = {
        # Map meta a/z to ctrl a/z
        "super.a" = "C-a";
        "super.z" = "C-z";

        # Quick access to escape key
        "j+k" = "esc";

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
    inherit (builtins) attrNames toJSON;
    inherit (lib) concatMapStringsSep getExe';
    toLuaBindings = bindings:
      if (attrNames bindings) == []
      then "{}"
      else
        "{\n"
        + concatMapStringsSep "\n" (name: "  [${toJSON name}] = ${toJSON bindings.${name}},") (attrNames bindings)
        + "\n}";
    toLuaRules = rules:
      if (attrNames rules) == []
      then "{}"
      else
        "{\n"
        + lib.concatMapStringsSep "\n" (
          name: "  { section = ${toJSON name}, bindings = ${toLuaBindings rules.${name}} },"
        )
        (attrNames rules)
        + "\n}";
  in
    # lua
    ''
      require("lib.keyd").apply(
        ${toJSON (getExe' pkgs.keyd "keyd")},
        ${toLuaRules cfg.windows},
        ${toLuaRules cfg.layers}
      )
    '';
}
