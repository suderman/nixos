{ config, lib, pkgs, ... }: let
  inherit (lib) getExe mkIf mkDefault;
  ini = pkgs.formats.ini {};
in {

  config = mkIf config.wayland.windowManager.hyprland.enable {

    programs.fuzzel = {
      enable = true;
      settings = {

        main = {
          fuzzy = "yes";
          # font = "${fontName}:size=14";
          icon-theme = "Papirus-Dark";
          width = 40;
          lines = 10;
          line-height = 25;
          dpi-aware = "no";
        };

        # All colors must be specified as a RGBA quadruple, in hex format, without a leading '0x'
        # https://man.archlinux.org/man/fuzzel.1.en#COLORS
        colors = mkDefault {
          background = "3f3f3fdf";       # zenburn-bg
          text = "dcdcccff";             # zenburn-fg
          match = "dca3a3ff";            # zenburn-red+1
          selection = "366060df";        # zenburn-blue-5
          selection-match = "dc8cc3ff";  # zenburn-magenta
          selection-text = "ace0e3ff";   # zenburn-blue+2
          border = "6ca0a3df";           # zenburn-blue-2
        };

        border = {
          width = 2;
          radius = 5;
        };

      };
    };

    # # extra packages
    # home.packages = with pkgs; [ 
    #   networkmanager_dmenu 
    #   papirus-icon-theme
    # ];
    #
    # xdg.configFile."networkmanager-dmenu/config.ini" = {
    #   source = ini.generate "config.ini" {
    #
    #     dmenu = {
    #       dmenu_command = "${getExe pkgs.fuzzel} -d";
    #       compact = "True";
    #       wifi_chars = "▂▄▆█";
    #       list_saved = "True";
    #     };
    #
    #     editor = {
    #       terminal = "kitty";
    #     };
    #
    #   }; 
    # };

  };

}
