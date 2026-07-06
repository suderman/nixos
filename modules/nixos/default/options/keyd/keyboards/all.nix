{
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

    # Next and back
    n = "M-right";
    b = "M-left";
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
    d = "mute";
    e = "ejectcd";
    h = "kpasterisk";
    j = "kpslash";
    k = "home";
    l = "pageup";
    semicolon = "left";
    apostrophe = "right";
    return = "enter";
    n = "kpplus";
    m = "kpminus";
    comma = "end";
    period = "pagedown";
    slash = "down";
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
    # Printscreen (screenshot)
    i = "sysrq";

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
  };

  # # Nav (text navigation and media keys)
  # nav = {
  #   # navigation
  #   k = "up";
  #   l = "right";
  #   j = "down";
  #   h = "left";
  #   w = "C-right";
  #   b = "C-left";
  #   p = "pageup"; # previous up
  #   n = "pagedown"; # next down
  #   comma = "home"; # < start of line
  #   dot = "end"; # > end of line
  #
  #   # hhkb arrow keys
  #   leftbrace = "up"; # [
  #   apostrophe = "right"; # '
  #   slash = "down"; # /
  #   semicolon = "left"; # ;
  #
  #   # Printscreen (screenshot)
  #   i = "sysrq";
  #
  #   # Media keys
  #   a = "volumedown"; # [a]djust down...
  #   s = "volumeup"; # [s]ound up!
  #   d = "mute"; # [d]on't play sound
  #   f = "nextsong"; # [f]orward
  #   r = "previoussong"; # [r]ewind
  #   z = "brightnessdown"; # [z]zz sleepy
  #   x = "brightnessup"; # need e[x]tra light
  #   c = "micmute"; # mi[c] mute
  #   v = "media"; # [v]olume source
  #   space = "playpause";
  #
  #   # Both volume keys together trigger media key
  #   # "a+s" = "media";
  #
  #   # Switch TTYs
  #   "1" = "C-A-f1";
  #   "2" = "C-A-f2";
  #   "3" = "C-A-f3";
  #   "4" = "C-A-f4";
  #   "5" = "C-A-f5";
  #   "6" = "C-A-f6";
  #   "7" = "C-A-f7";
  #   "8" = "C-A-f8";
  #   "9" = "C-A-f9";
  #
  #   # Toggle capslock
  #   rightshift = "capslock";
  # };

  # Shift+volume keys control tracks
  shift = {
    volumedown = "previoussong";
    volumeup = "nextsong";
    mute = "micmute";
  };
}
