{
  settings = {
    global = {
      chord_timeout = 50;
      chord_hold_timeout = 150;
    };
    main = {
      # [✥] nav is [space]
      space = "lettermod(nav, space, 200, 250)";

      # [𝅘𝅥𝅮] media is [z][/]
      z = "lettermod(media, z, 200, 250)";
      slash = "lettermod(media, slash, 200, 250)";

      f = "lettermod(super, f, 200, 250)";
      j = "lettermod(super, j, 200, 250)";

      c = "lettermod(control, c, 200, 250)";
      m = "lettermod(control, m, 200, 250)";

      d = "lettermod(alt, d, 200, 250)";
      k = "lettermod(alt, k, 200, 250)";

      s = "lettermod(shift, s, 200, 250)";
      l = "lettermod(shift, l, 200, 250)";

      # Chord pair for super+alt
      "d+f" = "layer(superalt)";
      "j+k" = "layer(superalt)";

      # Chord pair for super+shift
      "s+f" = "layer(supershift)";
      "j+l" = "layer(supershift)";

      # Chord pair for super+alt+shift
      "a+f" = "layer(superaltshift)";
      "j+semicolon" = "layer(superaltshift)";

      # Chord pair for ctrl+alt
      "d+c" = "layer(controlalt)";
      "m+k" = "layer(controlalt)";

      # Chord pair for ctrl+shift
      "s+c" = "layer(controlshift)";
      "m+l" = "layer(controlshift)";

      # Chord pair for ctrl+alt+shift
      "a+c" = "layer(controlaltshift)";
      "m+semicolon" = "layer(controlaltshift)";

      # Chord pair for alt+shift
      "s+d" = "layer(altshift)";
      "k+l" = "layer(altshift)";

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
      j = "volumedown";
      k = "volumeup";
      h = "previoussong";
      l = "nextsong";
      m = "media";
      n = "mute";
      u = "brightnessdown";
      i = "brightnessup";
    };
  };

  extraConfig = ''
    [super:M]
    space=M-space
    z=M-z
    slash=M-slash
    # c=M-c
    d=M-d
    f=M-f
    j=M-j
    k=M-k
    l=M-l
    m=M-m
    s=M-s

    [superalt:M-A]
    space=M-A-space
    z=M-A-z
    slash=M-A-slash
    c=M-A-c
    d=M-A-d
    f=M-A-f
    j=M-A-j
    k=M-A-k
    l=M-A-l
    m=M-A-m
    s=M-A-s

    [superaltshift:M-A-S]
    space=M-A-S-space
    z=M-A-S-z
    slash=M-A-S-slash
    c=M-A-S-c
    d=M-A-S-d
    f=M-A-S-f
    j=M-A-S-j
    k=M-A-S-k
    l=M-A-S-l
    m=M-A-S-m
    s=M-A-S-s

    [supershift:M-S]
    space=M-S-space
    z=M-S-z
    slash=M-S-slash
    c=M-S-c
    d=M-S-d
    f=M-S-f
    j=M-S-j
    k=M-S-k
    l=M-S-l
    m=M-S-m
    s=M-S-s

    [control:C]
    space=C-space
    z=C-z
    slash=C-slash
    c=C-c
    d=C-d
    f=C-f
    j=C-j
    k=C-k
    l=C-l
    m=C-m
    s=C-s

    [controlalt:C-A]
    space=C-A-space
    z=C-A-z
    slash=C-A-slash
    c=C-A-c
    d=C-A-d
    f=C-A-f
    j=C-A-j
    k=C-A-k
    l=C-A-l
    m=C-A-m
    s=C-A-s

    [controlshift:C-S]
    space=C-S-space
    z=C-S-z
    slash=C-S-slash
    c=C-S-c
    d=C-S-d
    f=C-S-f
    j=C-S-j
    k=C-S-k
    l=C-S-l
    m=C-S-m
    s=C-S-s

    [controlaltshift:C-A-S]
    space=C-A-S-space
    z=C-A-S-z
    slash=C-A-S-slash
    c=C-A-S-c
    d=C-A-S-d
    f=C-A-S-f
    j=C-A-S-j
    k=C-A-S-k
    l=C-A-S-l
    m=C-A-S-m
    s=C-A-S-s

    [alt:A]
    space=A-space
    z=A-z
    slash=A-slash
    c=A-c
    d=A-d
    f=A-f
    j=A-j
    k=A-k
    l=A-l
    m=A-m
    s=A-s

    [altshift:A-S]
    space=A-S-space
    z=A-S-z
    slash=A-S-slash
    c=A-S-c
    d=A-S-d
    f=A-S-f
    j=A-S-j
    k=A-S-k
    l=A-S-l
    m=A-S-m
    s=A-S-s

    [shift:S]
    space=S-space
    c=S-c
    d=S-d
    f=S-f
    j=S-j
    k=S-k
    l=S-l
    m=S-m
    s=S-s
  '';
}
