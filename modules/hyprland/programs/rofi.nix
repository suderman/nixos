{ config, lib, pkgs, ... }: let

  cfg = config.programs.rofi;
  ini = pkgs.formats.ini {};
  inherit (lib) getExe mkIf mkShellScript;

  hyprwindow = mkShellScript { 
    inputs = with pkgs; [ hyprland jq gawk gettext ]; 
    text = ../bin/hyprwindow.sh; 
  }; 

  # Toggle
  rofi-toggle = mkShellScript { 
    inputs = with pkgs; [ cfg.finalPackage procps keyd ]; 
    text = ../bin/rofi-toggle.sh; 
  }; 

in {

  config = mkIf config.wayland.windowManager.hyprland.enable {

    wayland.windowManager.hyprland.settings = {
      bindr = [ "super, Super_L, exec, ${rofi-toggle} -show combi" ];
      bind = [
        "super, space, exec, ${rofi-toggle} -show combi"
        # ''alt, tab, exec, ${rofi-toggle}  -show combi -kb-accept-entry "!Alt-Tab,!Alt+Alt_L" -kb-row-down "Alt+Tab" -selected-row 1''
        # ''super, tab, exec, ${rofi-toggle}  -show combi -kb-accept-entry "!Super-Tab,!Super+Super_L" -kb-row-down "Super+Tab" -selected-row 1''
      ];
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      plugins = with pkgs; [ rofi-calc rofi-emoji rofimoji ];
      cycle = false;
      terminal = getExe pkgs.kitty;
      font = "JetBrainsMono 14";
      extraConfig = {
        icon-theme = "Papirus";
        show-icons = true;
        modes = [ # drun keys recursivebrowser ssh window
          "combi"
          "calc"
          "emoji"
          # "emoji:${getExe pkgs.rofimoji}"
          # "filebrowser"
          # "run"
        ];
        combi-modes = [
          "hyprwindow:${hyprwindow}"
          "drun"
          "ssh"
        ];
        separator-style = "dash";
        color-enabled = true;
        display-hyprwindow = "";
        display-window = "";
        display-drun = "";
        display-run = "run";


        # kb-accept-entry = [ "space" "!Super+Super_L" ];
        # kb-cancel = [ "Super_L" "Escape" "Control+g" "Control+bracketleft" ];
        kb-accept-entry = [ "space" "Return" ];
        kb-mode-next = [ "Alt_L" "Shift+Right" "Control+Tab" ];
        kb-mode-previous = [ "Shift+Alt_L" "Shift+Left" "Control+ISO_Left_Tab" ];
        # kb-row-down = [ "Shift_R" "Down" "Control+n" "Super+j" ];
        # kb-row-up = [ "Shift_L" "Up" "Control+p" "Super+k" ];
        me-select-entry = "MousePrimary";
        me-accept-entry = "!MousePrimary";

        # rofi-calc
        calc-command = "echo -n '{result}' | wl-copy";
        kb-accept-custom = [ "backslash" "Control+Return" ];

      };

      theme = let l = config.lib.formats.rasi.mkLiteral; in {
        "*" = {
          bg0 =l "#252034E6";
          bg1 =l "#3C3B5480";
          bg2 =l "#01fdfeCC";
          fg0 =l "#DEDEDE";
          fg1 =l "#EEFAF2";
          fg2 =l "#252034";
          fg3 =l "#70788080";
          background-color =l "transparent";
          margin = 0;
          padding = 0;
          spacing = 0;
          text-color =l "@fg0";
        };

        element = {
          background-color =l "transparent";
          padding =l "8px 16px";
          spacing =l "16px";
        };

        "element normal active" = {
          text-color =l "@bg2";
        };

        "element selected active" = {
          background-color =l "@bg2";
          text-color =l "@fg2";
        };

        "element selected normal" = {
          background-color =l "@bg2";
          text-color =l "@fg2";
        };

        element-icon = {
          size =l "32px";
          vertical-align =l "0.5";
        };

        element-text = {
          text-color =l "inherit";
          vertical-align =l "0.5";
          tab-stops = map l [ "200px" ];
        };

        entry = {
          placeholder = "Search";
          placeholder-color =l "@fg3";
          vertical-align =l "0.5";
        };

        icon-search = {
          expand = false;
          filename = "search";
          size =l "28px";
          vertical-align =l "0.5";
        };

        inputbar = {
          children = map l [ "icon-search" "entry" ];
          padding =l "12px";
          spacing =l "12px";
        };

        listview = {
          border =l "1px 0 0";
          border-color =l "@bg1";
          columns = 1;
          fixed-height = false;
          lines = 10;
        };

        message = {
          background-color =l "@bg1";
          border =l "2px 0 0";
          border-color =l "@bg1";
        };

        textbox = {
          padding =l "8px 24px";
        };

        window = {
          anchor =l "north";
          background-color =l "@bg0";
          border-radius = 8;
          position =l "north";
          width =l "65%";
          y-offset =l "-25%";
        };

      };
    };

    # extra packages
    home.packages = with pkgs; [ 
      networkmanager_dmenu 
      papirus-icon-theme
    ];

    xdg.configFile."networkmanager-dmenu/config.ini" = {
      source = ini.generate "config.ini" {
        dmenu = {
          dmenu_command = "${getExe cfg.finalPackage} -dmenu";
          compact = "True";
          wifi_chars = "▂▄▆█";
          list_saved = "True";
        };
        editor.terminal = "kitty";
      }; 
    };

  };

}
