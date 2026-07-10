let
  concatLines = builtins.concatStringsSep "\n";
  passthrough = layer: mod: keys: ''
    [${layer}]
    ${concatLines (builtins.map (key: "${key} = ${mod}-${key}") keys)}
  '';
  # When using real modifiers, these homerow mod keys should be pass through
  modKeys =
    ["d" "s" "f" "j" "k" "l"]
    ++ ["z" "c" "m" "slash"]
    ++ ["space"];

  # lettermod(<layer>, <key>, <idle timeout>, <hold timeout>)
  lettermod = layer: key: "lettermod(${layer}, ${key}, 200, 400)";
in {
  settings = {
    global = {
      chord_timeout = 50;
      chord_hold_timeout = 150;
      default_layout = "typing";
    };

    # Shared tab-as-fn behavior
    main.tab = "overloadt2(fn, tab, 200)";

    # Default typing layout
    "typing:layout" = {
      # [✥] nav is [space]
      space = lettermod "nav" "space";

      # [𝅘𝅥𝅮] media is [z][/]
      z = lettermod "media" "z";
      slash = lettermod "media" "slash";

      # Lettermod for super
      c = lettermod "super" "c";
      m = lettermod "super" "m";

      # Lettermod for ctrl
      f = lettermod "control" "f";
      j = lettermod "control" "j";

      # Lettermod for alt
      d = lettermod "alt" "d";
      k = lettermod "alt" "k";

      # Lettermod for shift
      s = lettermod "shift" "s";
      l = lettermod "shift" "l";

      # Both volume keys together trigger media key
      "volumedown+volumeup" = "media";
    };

    # Super (meta) layer
    "super:M" = {
      # Open window switcher (super tab)
      tab = "swapm(switcher, M-tab)";

      # Cut/Copy/Paste clipboard
      x = "S-delete";
      c = "C-insert";
      v = "S-insert";
    };

    # Switcher (while holding down meta/super-tab)
    "switcher:M" = {
      # Super-Tab: Switch to next window
      tab = "M-A-tab";

      # Super-Backtick\Esc: Switch to previous window
      grave = "M-S-tab";
      esc = "M-S-tab";

      # Next and previous
      n = "M-right";
      p = "M-left";
    };

    # Replicate the function layer on hhkb
    fn = {
      "1" = "f1";
      "2" = "f2";
      "3" = "f3";
      "4" = "f4";
      "5" = "f5";
      "6" = "f6";
      "7" = "f7";
      "8" = "f8";
      "9" = "f9";
      "0" = "f10";
      minus = "f11";
      equal = "f12";
      backslash = "insert";
      grave = "delete";
      tab = "capslock";
      i = "sysrq";
      o = "scrolllock";
      p = "pause";
      leftbrace = "up";
      backspace = "numlock";
      a = "volumedown";
      s = "volumeup";
      d = "mute";
      e = "ejectcd";
      h = "kpasterisk";
      j = "kpslash";
      k = "home";
      l = "pageup";
      semicolon = "left";
      apostrophe = "right";
      enter = "enter";
      n = "kpplus";
      m = "kpminus";
      comma = "end";
      dot = "pagedown";
      slash = "down";
    };

    nav = {
      # vim navigation
      k = "up";
      l = "right";
      j = "down";
      h = "left";
      w = "C-right";
      b = "C-left";
      p = "pageup"; # previous up
      n = "pagedown"; # next down
      a = "home"; # < start of line
      e = "end"; # > end of line

      # hhkb arrow keys
      leftbrace = "up"; # [
      apostrophe = "right"; # '
      slash = "down"; # /
      semicolon = "left"; # ;

      # Switch TTYs
      "1" = "C-A-f1";
      "2" = "C-A-f2";
      "3" = "C-A-f3";
      "4" = "C-A-f4";
      "5" = "C-A-f5";
      "6" = "C-A-f6";
      "7" = "C-A-f7";
      "8" = "C-A-f8";
      "9" = "C-A-f9";
    };

    # media keys
    media = {
      a = "volumedown"; # [a]djust down...
      s = "volumeup"; # [s]ound up!
      d = "mute"; # [d]on't play sound
      f = "nextsong"; # [f]orward
      r = "previoussong"; # [r]ewind
      z = "brightnessdown"; # [z]zz sleepy
      x = "brightnessup"; # need e[x]tra light
      c = "micmute"; # mi[c] mute
      v = "media"; # [v]olume source

      space = "playpause";

      # right side
      h = "previoussong";
      j = "volumedown";
      k = "volumeup";
      l = "nextsong";
      p = "brightnessup";
      n = "brightnessdown";
      m = "media";
      comma = "micmute";
      dot = "mute";
    };
  };

  # Physical modifier layers explicitly pass mod keys through so real modifiers do not trigger typing-layer lettermods.
  extraConfig = concatLines [
    (passthrough "control:C" "C" modKeys)
    (passthrough "alt:A" "A" modKeys)
    (passthrough "shift:S" "S" modKeys)
    # skip c because we already defined it to copy (C-insert)
    (passthrough "super:M" "M" (builtins.filter (key: key != "c") modKeys))
    ''

      [superalt:M-A]

      [superaltshift:M-A-S]

      [supershift:M-S]

      [controlalt:C-A]

      [controlshift:C-S]

      [controlaltshift:C-A-S]

      [altshift:A-S]

    ''
    # Chords are raw config because keyd chord parsing is order-sensitive.
    ''
      [typing:layout]
      c+d = layer(superalt)
      m+k = layer(superalt)

      c+s = layer(supershift)
      m+l = layer(supershift)

      f+d = layer(controlalt)
      j+k = layer(controlalt)

      f+s = layer(controlshift)
      j+l = layer(controlshift)

      d+s = layer(altshift)
      k+l = layer(altshift)

      c+d+s = layer(superaltshift)
      m+k+l = layer(superaltshift)

      f+d+s = layer(controlaltshift)
      j+k+l = layer(controlaltshift)
    ''
    # Empty gaming layout for vanilla keyboard experience, toggled with fn+g (tab+g)
    ''

      [gaming:layout]

      [typing+fn]
      g = setlayout(gaming)

      [gaming+fn]
      g = setlayout(typing)

    ''
  ];
}
