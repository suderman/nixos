# Audio visualizer
{ config, lib, pkgs, ... }: {

  programs.cava = {
    enable = true;
    settings = {

      input = {
        method = "pulse";
        source = "auto";
      };
      
      color = with config.lib.stylix.colors.withHashtag; {
        background = "'${base00}'";
        gradient = 1;
        gradient_count = 8;
        gradient_color_1 = "'${base08}'";
        gradient_color_2 = "'${base09}'";
        gradient_color_3 = "'${base0A}'";
        gradient_color_4 = "'${base0B}'";
        gradient_color_5 = "'${base0C}'";
        gradient_color_6 = "'${base0D}'";
        gradient_color_7 = "'${base0E}'";
        gradient_color_8 = "'${base0F}'";
      };

    };
  };

}
