{ config, lib, pkgs, ... }: let 

  cfg = config.modules.hyprland;
  inherit (builtins) toJSON;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
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

  };

}
