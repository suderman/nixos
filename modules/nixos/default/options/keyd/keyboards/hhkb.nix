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
      leftcontrol = "overloadt2(control, escape, 200)";

      # Tap real left modifiers for standalone actions; hold as modifiers.
      leftshift = "layer(shift)";
      leftalt = "overload(alt, f13)";
      leftmeta = "overload(super, f14)";

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

    "shift:S" = {
      leftalt = "overload(alt, S-f13)";
    };
  };
}
