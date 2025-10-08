# programs.bluetuith.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.bluetuith;
  inherit (lib) mkIf options;
in {
  options.programs.bluetuith.enable = options.mkEnableOption "bluetuith";
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

    wayland.windowManager.hyprland.settings.bind = [
      # shift+media to manage bluetooth connections
      "shift, XF86AudioMedia, exec, export addr=$(bluetoothctl devices | rofi-toggle -dmenu | cut -d' ' -f2); bluetoothctl unblock $addr; bluetoothctl connect $addr"
    ];
  };
}
