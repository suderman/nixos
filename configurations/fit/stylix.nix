{ config, pkgs, lib, ... }: {

  stylix = {
    enable = true;
    polarity = "dark";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";
    opacity.terminal = 0.85;
    cursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = 46;
    };
  };

}
