# programs.bluetuith.enable = true;
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.programs.bluetuith;
  inherit (lib) mkIf mkEnableOption optionalAttrs;
in {
  disabledModules = ["programs/bluetuith.nix"];
  options.programs.bluetuith.enable = mkEnableOption "bluetuith";
  config = mkIf cfg.enable {
    home.packages = [pkgs.bluetuith];

    # https://darkhz.github.io/bluetuith/Configuration.html
    xdg.configFile = {
      "bluetuith/bluetuith.conf".text = builtins.toJSON {
        theme = {};
        receive-dir = "";
        keybindings = {
          NavigateDown = "j";
          NavigateUp = "k";
          Menu = "l";
          Close = "h";
          Quit = "q";
        };
      };
    };

    wayland.windowManager.hyprland = optionalAttrs (options.wayland.windowManager.hyprland ? lua) {
      lua.features.bluetuith = ''
        util.exec("SHIFT + XF86AudioMedia", "export addr=$(bluetoothctl devices | rofi-toggle -dmenu | cut -d' ' -f2); bluetoothctl unblock $addr; bluetoothctl connect $addr")
      '';
    };
  };
}
