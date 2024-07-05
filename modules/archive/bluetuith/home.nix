{ config, lib, pkgs, ... }: let 

  cfg = config.modules.bluetuith;
  inherit (builtins) toJSON;
  inherit (lib) mkIf;

in {

  options.modules.bluetuith = {
    enable = lib.options.mkEnableOption "bluetuith"; 
  };

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
