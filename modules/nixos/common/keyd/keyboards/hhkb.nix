# HHKB Pro 2
# https://www.amazon.ca/gp/product/B07K9V58DP/
# 1 = OFF    # Macintosh mode (enable media keys)
# 2 = ON     #
# 3 = ON     # Delete = BS
# 4 = OFF    # Left Meta = Left Meta (don't reassign to Fn)
# 5 = OFF    # Meta = Meta, Alt = Alt (don't swap modifiers)
# 6 = ON     # Wake Up Enable
{
  ids = [ "0853:0100" "04fe:0006" ];
  settings = {
    main = {

      # Use tab as custom modifier
      tab = "overloadt2(nav, tab, 200)";

      # Leave the default modifiers as-is
      leftshift = "layer(shift)";
      leftalt = "layer(alt)";
      leftmeta = "layer(super)";
      rightmeta = "layer(super)";
      rightalt = "layer(alt)";
      rightshift = "layer(shift)";

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

      # Both volume keys together trigger media key
      "volumedown+volumeup" = "media";

    };

  } // import ./all.nix;

}
