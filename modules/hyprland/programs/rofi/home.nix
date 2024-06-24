{ config, lib, pkgs, ... }: let
  inherit (lib) getExe mkIf mkShellScript;
  inherit (config.lib.formats.rasi) mkLiteral;

  # rofi = pkgs.rofi-wayland;
  fontName = "JetBrains Mono";
  fontSize = 16;
  terminal = getExe pkgs.kitty;

  window = mkShellScript {
    inputs = with pkgs; [ hyprland jq coreutils libnotify ];
    text = ''
      if [ -z "''${1-}" ]; then
        hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | "\(.focusHistoryID) \(.class) :: \(.title)"'
      else
        printf -v id '%d\n' "$(echo "$@" | cut -d" " -f1)" 2>/dev/null
        addr="$(hyprctl clients -j | jq -r ".[] | select(.focusHistoryID==$id) | .address")"
        coproc hyprctl dispatch focuswindow address:$addr 2>&1
      fi
    '';
  };

in {

  config = mkIf config.wayland.windowManager.hyprland.enable {
    
    # home.packages = with pkgs; [
    #   rofi
    #   rofi-bluetooth bc
    #   rofi-pulse-select
    #   rofi-calc 
    #   rofi-emoji
    # ];

    # home.file.".config/rofi/config.rasi".text = ''
    #   configuration {
    #     cycle: true;
    #     color-enabled: true;
    #     terminal: "${terminal}";
    #     font: "${fontName} ${builtins.toString fontSize}";
    #     show-icons: true;
    #     icon-theme: "Papirus";
    #     separator-style: "dash";
    #     modi: "combi";
    #     combi-modi: "calc,run,drun,ssh,emoji";
    #     me-accept-entry: "!MousePrimary";
    #     me-select-entry: "MousePrimary";
    #     display-drun: "";
    #     display-run: "";
    #     location: 0;
    #     xoffset: 0;
    #     yoffset: 0;
    #   }
    #   @theme "/dev/null"
    # '' + builtins.readFile ./style.css;

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
      terminal = getExe pkgs.kitty;
      font = "JetBrainsMono 16";
      cycle = true;
      extraConfig = {
        modes = [
          "calc"
          "combi"
          "drun"
          "emoji"
          "filebrowser"
          "keys"
          "recursivebrowser"
          "run"
          "ssh"
          "window:${window}"
        ];
        combi-modes = [
          "window"
          "drun"
          "ssh"
        ];
        # combi-display-format = "{mode} <---> {text}";
        separator-style = "dash";
        show-icons = true;
        icon-theme = "Papirus";
        color-enabled = true;
        me-select-entry = "MousePrimary";
        me-accept-entry = "!MousePrimary";
        display-window = "";
        display-drun = "";
        display-run = "";
      };
      theme = ./style.css;
      # theme' = let l = true; in {
      #
      #   "*" = {
      #     bg0 =l "#252034E6";
      #     bg1 =l "#3C3B5480";
      #     bg2 =l "#01fdfeCC";
      #     fg0 =l "#DEDEDE";
      #     fg1 =l "#EEFAF2";
      #     fg2 =l "#252034";
      #     fg3 =l "#70788080";
      #   };
      # };
      #
      #     background-color = mkLiteral "transparent";
      #     text-color = mkLiteral "@fg0";
      #
      #     margin = 0;
      #     padding = 0;
      #     spacing = 0;
      #   };
      #
      #   window = {
      #     background-color = mkLiteral "@bg0";
      #     position = mkLiteral "north";
      #     width = mkLiteral "35%";
      #     y-offset = mkLiteral "-25%";
      #     anchor = mkLiteral "north";
      #     border-radius = 8;
      #   };
      #
      #   inputbar = {
      #     padding = mkLiteral "12px";
      #     spacing = mkLiteral "12px";
      #     children = map mkLiteral [ "icon-search" "entry" ];
      #   };
      #
      #   icon-search = {
      #     expand = false;
      #     filename = "search";
      #     size = mkLiteral "28px";
      #     vertical-align = mkLiteral "0.5";
      #   };
      #
      #   entry = {
      #     placeholder = "Search";
      #     placeholder-color = mkLiteral "@fg3";
      #     vertical-align = mkLiteral "0.5";
      #   };
      #
      #   message = {
      #     border = mkLiteral "2px 0 0";
      #     border-color = mkLiteral "@bg1";
      #     background-color = mkLiteral "@bg1";
      #   };
      #
      #   textbox = {
      #     padding = mkLiteral "8px 24px";
      #   };
      #
      #   listview = {
      #     lines = 10;
      #     columns = 1;
      #     fixed-height = false;
      #     border = mkLiteral "1px 0 0";
      #     border-color = mkLiteral "@bg1";
      #   };
      #
      #   element = {
      #     padding = mkLiteral "8px 16px";
      #     spacing = mkLiteral "16px";
      #     background-color = mkLiteral "transparent";
      #   };
      #
      #   element-icon = {
      #     size = mkLiteral "1em";
      #     vertical-align = mkLiteral "0.5";
      #   };
      #
      #   element-text = {
      #     text-color = mkLiteral "inherit";
      #     vertical-align = mkLiteral "0.5";
      #   };
      #
      #   "element normal active" = {
      #     text-color = mkLiteral "@bg2";
      #   };
      #
      #   "element selected normal" = {
      #     background-color = mkLiteral "@bg2";
      #     text-color = mkLiteral "@fg2";
      #   };
      #
      #   "element selected active" = {
      #     background-color = mkLiteral "@bg2";
      #     text-color = mkLiteral "@fg2";
      #   };
      # };
    };

  };

}
