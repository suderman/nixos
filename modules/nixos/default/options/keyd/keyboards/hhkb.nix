# HHKB Pro 2
# https://www.amazon.ca/gp/product/B07K9V58DP/
# 1 = OFF    # Macintosh mode (enable media keys)
# 2 = ON     #
# 3 = ON     # Delete = BS
# 4 = OFF    # Left Meta = Left Meta (don't reassign to Fn)
# 5 = OFF    # Meta = Meta, Alt = Alt (don't swap modifiers)
# 6 = ON     # Wake Up Enable
{
  ids = ["0853:0100" "04fe:0006"];
  settings = {
    main = {
      # Use tab as custom modifier
      tab = "overloadt2(fn, tab, 200)";

      # Tapping left control is escape
      leftcontrol = "overloadt2(control, escape, 100)";

      # Leave the default modifiers as-is
      leftshift = "layer(shift)";
      leftalt = "layer(alt)";
      leftmeta = "layer(super)";
      # leftalt = "overloadt2(alt, F13, 100)";
      # leftmeta = "overloadt2(super, F14, 100)";

      # Allow right modifers to be unique keys
      rightmeta = "rightmeta";
      rightalt = "rightalt";
      rightshift = "rightshift";

      # Fn keypad as media keys
      # [+] next song
      # [-] previous song
      # [*] play-pause
      # [/] media program
      kpplus = "nextsong";
      kpminus = "previoussong";
      kpasterisk = "playpause";
      kpslash = "media";

      # Pause/Break key as media play-pause
      pause = "playpause";
    };
  };
}
