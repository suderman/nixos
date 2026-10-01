{
  config,
  lib,
  pkgs,
  ...
}: let
  l = v: lib.mkDefault (config.lib.formats.rasi.mkLiteral v);
  colors = config.lib.stylix.colors;
in {
  home.packages = [
    pkgs.candy-icons
    pkgs.papirus-icon-theme
  ];

  stylix.targets.rofi.enable = lib.mkIf config.programs.desktop-theme.enable false;

  programs.rofi = {
    font = lib.mkDefault "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
    theme = {
      "*" = {
        bg0 = l "#${colors.base00}F2";
        bg1 = l "#${colors.base02}80";
        bg2 = l "#${colors.base0D}";
        fg0 = l "#${colors.base05}";
        fg1 = l "#${colors.base06}";
        fg2 = l "#${colors.base00}";
        fg3 = l "#${colors.base04}";
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

      "button selected" = {
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
        filename = "searching";
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
        width = l "50%";
        y-offset = l "-25%";
      };
    };
  };

  xdg.dataFile."rofi/themes/custom.rasi".text = lib.mkIf config.programs.desktop-theme.enable (lib.mkAfter ''
    @import "${config.xdg.stateHome}/desktop-theme/current/rofi.rasi"
  '');

  # Use a real file for the rofi theme to ease real-time tinkering
  home.localStorePath = [".local/share/rofi/themes/custom.rasi"];
}
