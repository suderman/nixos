{
  config,
  lib,
  pkgs,
  ...
}: let
  l = v: lib.mkDefault (config.lib.formats.rasi.mkLiteral v);
in {
  home.packages = [pkgs.papirus-icon-theme];

  programs.rofi.theme = {
    "*" = {
      bg0 = l "#252034E6";
      bg1 = l "#3C3B5480";
      bg2 = l "#01fdfeCC";
      fg0 = l "#DEDEDE";
      fg1 = l "#EEFAF2";
      fg2 = l "#252034";
      fg3 = l "#70788080";
      background-color = l "transparent";
      margin = 0;
      padding = 0;
      spacing = 0;
      text-color = l "@fg0";
    };

    element = {
      background-color = l "transparent";
      padding = l "8px 16px";
      spacing = l "16px";
    };

    "element normal active" = {
      text-color = l "@bg2";
    };

    "element selected active" = {
      background-color = l "@bg2";
      text-color = l "@fg2";
    };

    "element selected normal" = {
      background-color = l "@bg2";
      text-color = l "@fg2";
    };

    element-icon = {
      size = l "32px";
      vertical-align = l "0.5";
    };

    element-text = {
      text-color = l "inherit";
      vertical-align = l "0.5";
      tab-stops = map l ["250px"];
    };

    entry = {
      placeholder = "Search";
      placeholder-color = l "@fg3";
      vertical-align = l "0.5";
    };

    icon-search = {
      expand = false;
      filename = "search";
      size = l "28px";
      vertical-align = l "0.5";
    };

    inputbar = {
      children = map l ["icon-search" "entry"];
      padding = l "12px";
      spacing = l "12px";
    };

    listview = {
      border = l "1px 0 0";
      border-color = l "@bg1";
      columns = 1;
      fixed-height = false;
      lines = 10;
    };

    message = {
      background-color = l "@bg1";
      border = l "2px 0 0";
      border-color = l "@bg1";
    };

    textbox = {
      padding = l "8px 24px";
    };

    window = {
      anchor = l "north";
      background-color = l "@bg0";
      border-radius = 8;
      position = l "north";
      width = l "65%";
      y-offset = l "-25%";
    };
  };

  # Use a real file for the rofi theme to ease real-time tinkering
  home.localStorePath = [".local/share/rofi/themes/custom.rasi"];
}
