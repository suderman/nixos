{
  settings = {
    global = {
      chord_timeout = 50;
      chord_hold_timeout = 0;
    };
    main = {
      # Chord pair for super
      # [ ][ ][d][f][ ]  |  [ ][j][k][ ][ ]
      "d+f" = "layer(super)";
      "j+k" = "layer(super)";

      # Chord pair for super+alt
      # [ ][s][ ][f][ ]  |  [ ][j][ ][l][ ]
      "s+f" = "layer(superalt)";
      "j+l" = "layer(superalt)";

      # Chord pair for super+shift
      # [a][ ][ ][f][ ]  |  [ ][j][ ][ ][;]
      "a+f" = "layer(supershift)";
      "j+semicolon" = "layer(supershift)";

      # Chord pair for super+alt+shift
      # [a][ ][ ][ ][g]  |  [h][ ][ ][ ][;]
      "a+g" = "layer(superaltshift)";
      "h+semicolon" = "layer(superaltshift)";

      # Chord pair for ctrl
      # [ ][ ][d][ ][ ]  |  [ ][ ][k][ ][ ]
      #    [ ][ ][c][ ]  |  [ ][m][ ][ ]
      "d+c" = "layer(control)";
      "m+k" = "layer(control)";

      # Chord pair for ctrl+alt
      # [ ][s][ ][ ][ ]  |  [ ][ ][ ][l][ ]
      #    [ ][ ][c][ ]  |  [ ][m][ ][ ]
      "s+c" = "layer(controlalt)";
      "m+l" = "layer(controlalt)";

      # Chord pair for ctrl+shift
      # [a][ ][ ][ ][ ]  |  [ ][ ][ ][ ][;]
      #    [ ][ ][c][ ] | [ ][m][ ][ ]
      "a+c" = "layer(controlshift)";
      "m+semicolon" = "layer(controlshift)";

      # Chord pair for ctrl+alt+shift
      # [a][ ][ ][ ][ ]  |  [ ][ ][ ][ ][;]
      #    [ ][ ][ ][v] | [n][ ][ ][ ]
      "a+v" = "layer(controlaltshift)";
      "n+semicolon" = "layer(controlaltshift)";

      # Chord pair for alt
      # [ ][s][d][ ][ ]  |  [ ][ ][k][l][ ]
      "s+d" = "layer(alt)";
      "k+l" = "layer(alt)";

      # Chord pair for alt+shift
      # [a][ ][d][ ][ ]  |  [ ][ ][k][ ][;]
      "a+d" = "layer(altshift)";
      "k+semicolon" = "layer(altshift)";

      # Chord pair for shift
      # [a][s][ ][ ][ ]  |  [ ][ ][ ][k][;]
      "a+s" = "layer(shift)";
      "l+semicolon" = "layer(shift)";

      # Chord pair for fn
      # [ ][ ][e][r][ ]  |  [ ][u][i][ ][ ]
      "e+r" = "layer(fn)";
      "u+i" = "layer(fn)";

      # Chord pair for ctrl-fn
      # [ ][w][ ][r][ ]  |  [ ][u][ ][o][ ]
      "w+r" = "layer(controlfn)";
      "u+o" = "layer(controlfn)";

      # Chord pair for alt-fn
      # [q][ ][ ][r][ ]  |  [ ][u][ ][ ][p]
      "q+r" = "layer(altfn)";
      "u+p" = "layer(altfn)";

      # Chord pair for media
      # [z][x][ ][ ][ ]  |  [ ][ ][ ][,][.]
      "z+x" = "layer(media)";
      "comma+dot" = "layer(media)";

      # Both volume keys together trigger media key
      "volumedown+volumeup" = "media";

      # [✥] nav is [space]
      space = "lettermod(nav, space, 200, 220)";
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

    "controlfn:C" = {
      "1" = "C-f1";
      "2" = "C-f2";
      "3" = "C-f3";
      "4" = "C-f4";
      "5" = "C-f5";
      "6" = "C-f6";
      "7" = "C-f7";
      "8" = "C-f8";
      "9" = "C-f9";
      "0" = "C-f10";
      minus = "C-f11";
      equal = "C-f12";
    };

    "altfn:A" = {
      "1" = "A-f1";
      "2" = "A-f2";
      "3" = "A-f3";
      "4" = "A-f4";
      "5" = "A-f5";
      "6" = "A-f6";
      "7" = "A-f7";
      "8" = "A-f8";
      "9" = "A-f9";
      "0" = "A-f10";
      minus = "A-f11";
      equal = "A-f12";
    };

    # Nav (text navigation)
    nav = {
      # navigation
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
      # Media keys
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
    [superalt:M-A]
    space=M-A-space
    [superaltshift:M-A-S]
    space=M-A-S-space
    [supershift:M-S]
    space=M-S-space
    [control:C]
    space=C-space
    [controlalt:C-A]
    space=C-A-space
    [controlshift:C-S]
    space=C-S-space
    [controlaltshift:C-A-S]
    space=C-A-S-space
    [alt:A]
    space=A-space
    [altshift:A-S]
    space=A-S-space
    [shift:S]
    space=S-space
    [controlfn:C]
    [altfn:A]
  '';
}
