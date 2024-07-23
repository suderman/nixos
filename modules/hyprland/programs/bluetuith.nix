{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (builtins) toJSON;
  inherit (lib) mkIf getExe;

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
      bluez
      bluetuith
    ];

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

    wayland.windowManager.hyprland.settings = {
      bind = with pkgs; [

        # Bluetooth connection
        "shift, XF86AudioMedia, exec, export addr=$(bluetoothctl devices | rofi-toggle -dmenu | cut -d' ' -f2); bluetoothctl unblock $addr; bluetoothctl connect $addr"

      ];
    };

  };

}
