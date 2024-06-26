{ config, lib, pkgs, ... }: let
  inherit (lib) getExe mkIf mkShellScript;

  hyprwindow = mkShellScript { 
    inputs = with pkgs; [ hyprland jq libnotify ]; 
    text = ../bin/hyprwindow.sh; 
  }; 

in {

  config = mkIf config.wayland.windowManager.hyprland.enable {
    
    wayland.windowManager.hyprland.settings.bind = let
      rofi = getExe config.programs.rofi.finalPackage;
    in [
      "super, space, exec, ${rofi} -show combi"
      # ''alt, tab, exec, ${getExe config.programs.rofi.package} -show combi -kb-accept-entry "!Alt-Tab,!Alt+Alt_L" -kb-row-down "Alt+Tab" -selected-row 1''
    ];

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      plugins = with pkgs; [ rofi-calc rofi-emoji ];
      cycle = true;
      terminal = getExe pkgs.kitty;
      font = "JetBrainsMono 16";
      extraConfig = {
        icon-theme = "Papirus";
        show-icons = true;
        modes = [ # drun keys recursivebrowser ssh window
          "combi"
          "calc"
          "emoji"
          "filebrowser"
          "run"
        ];
        combi-modes = [
          "hyprwindow:${hyprwindow}"
          "drun"
          "ssh"
        ];
        separator-style = "dash";
        color-enabled = true;
        me-select-entry = "MousePrimary";
        me-accept-entry = "!MousePrimary";
        display-hyprwindow = "";
        display-window = "";
        display-drun = "";
        display-run = "run";
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
          # tab-stops =l "[50px, 200px]";
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
          width =l "35%";
          y-offset =l "-25%";
        };

      };
    };

  };

}
