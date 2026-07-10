let
  concatLines = builtins.concatStringsSep "\n";
  keyMap = f: keys:
    builtins.listToAttrs (builtins.map (key: {
        name = key;
        value = f key;
      })
      keys);
  plainKeys = keyMap (key: key);
  modifiedKeys = mod: keyMap (key: "${mod}-${key}");

  # letter keys on the left side of the keyboard
  leftHandKeys =
    ["q" "w" "e" "r" "t"]
    ++ ["a" "s" "d" "f" "g"]
    ++ ["z" "x" "c" "v" "b"];

  # letter keys on the right side of the keyboard
  rightHandKeys =
    ["y" "u" "i" "o" "p"]
    ++ ["h" "j" "k" "l" "semicolon"]
    ++ ["n" "m" "comma" "dot" "slash"];

  # active modifier layers need explicit pass-through for other home-row mod keys.
  modKeys =
    ["d" "s" "f" "j" "k" "l"]
    ++ ["z" "c" "m" "slash"]
    ++ ["space"];
  guardedModLayer = mod: handKeys: modifiedKeys mod modKeys // plainKeys handKeys;

  # custom behaviour of super key everywhere
  superBindings = {
    # Open window switcher (super tab)
    tab = "swapm(switcher, M-tab)";

    # Cut/Copy/Paste clipboard
    x = "S-delete";
    c = "C-insert";
    v = "S-insert";
  };
  superModKeys = builtins.filter (key: key != "c") modKeys;
  guardedSuperLayer = handKeys: modifiedKeys "M" superModKeys // plainKeys handKeys // superBindings;

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
      c = lettermod "leftsuper" "c";
      m = lettermod "rightsuper" "m";

      # Lettermod for ctrl
      f = lettermod "leftcontrol" "f";
      j = lettermod "rightcontrol" "j";

      # Lettermod for alt
      d = lettermod "leftalt" "d";
      k = lettermod "rightalt" "k";

      # Lettermod for shift
      s = lettermod "leftshift" "s";
      l = lettermod "rightshift" "l";

      # Both volume keys together trigger media key
      "volumedown+volumeup" = "media";
    };

    # Control layer
    "control:C" = modifiedKeys "C" modKeys;
    # Home-row ctrl layers shadow same-hand letters as plain keys to avoid roll mistakes
    "leftcontrol:C" = guardedModLayer "C" leftHandKeys;
    "rightcontrol:C" = guardedModLayer "C" rightHandKeys;

    # Alt layer
    "alt:A" = modifiedKeys "A" modKeys;
    # Home-row alt layers shadow same-hand letters as plain keys to avoid roll mistakes
    "leftalt:A" = guardedModLayer "A" leftHandKeys;
    "rightalt:A" = guardedModLayer "A" rightHandKeys;

    # Shift layer
    "shift:S" = modifiedKeys "S" modKeys;
    # Home-row shift layers shadow same-hand letters as plain keys to avoid roll mistakes
    "leftshift:S" = guardedModLayer "S" leftHandKeys;
    "rightshift:S" = guardedModLayer "S" rightHandKeys;

    # Super (meta) layer
    "super:M" = modifiedKeys "M" superModKeys // superBindings;
    # Home-row super layers shadow same-hand letters as plain keys to avoid roll mistakes
    "leftsuper:M" = guardedSuperLayer leftHandKeys;
    "rightsuper:M" = guardedSuperLayer rightHandKeys;

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

  # Keep order-sensitive keyd config raw; generated settings sort entries alphabetically.
  extraConfig = concatLines [
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
