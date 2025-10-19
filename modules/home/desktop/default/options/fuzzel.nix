# programs.fuzzel.enable = true
{lib, ...}: {
  programs.fuzzel = {
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
      colors = lib.mkDefault {
        background = "3f3f3fdf"; # zenburn-bg
        text = "dcdcccff"; # zenburn-fg
        match = "dca3a3ff"; # zenburn-red+1
        selection = "366060df"; # zenburn-blue-5
        selection-match = "dc8cc3ff"; # zenburn-magenta
        selection-text = "ace0e3ff"; # zenburn-blue+2
        border = "6ca0a3df"; # zenburn-blue-2
      };

      border = {
        width = 2;
        radius = 5;
      };
    };
  };
}
