# HHKB Pro 2
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

      # Modifers
      tab = "overload(nav, tab)";
      leftalt = "layer(alt)";
      leftmeta = "layer(meta)";
      rightmeta = "layer(meta)";
      rightalt = "layer(alt)";

      # Fn keypad as media keys
      # [+] next song
      # [-] previous song
      # [/] play pause
      # [*] media program
      kpplus = "nextsong";
      kpminus = "previoussong";
      kpasterisk = "media";
      kpslash = "playpause";

    };

  } // import ./all.nix;

}
