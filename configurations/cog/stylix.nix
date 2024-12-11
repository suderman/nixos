{ config, lib, pkgs, ... }: {

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";
    opacity.terminal = 0.85;
    cursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = 36;
    };
  };

}
