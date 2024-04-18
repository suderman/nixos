{ config, lib, pkgs, ... }: let 

  cfg = config.modules.hyprland;
  inherit (lib) mkIf;

  command = "fuzzle -d"; 

in {

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ 
      networkmanager_dmenu 
    ];

    xdg.configFile."networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${command}

      compact = True
      wifi_chars = ▂▄▆█
      list_saved = True

      [editor]
      terminal = alacritty
      # gui_if_available = <True or False> (Default: True)
    '';
  };

}
