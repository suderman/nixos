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

  # Nav (Vim & Emacs style navigation)
  nav = {
    # vi keys
    k = "up";
    l = "right";
    j = "down";
    h = "left";
    # u = "pageup";
    # d = "pagedown";
    w = "C-right";
    b = "C-left";

    # emacs keys
    q = "home"; # normally a
    e = "end";
    # b = "left";
    # f = "right";
    p = "pageup";
    n = "pagedown";

    # hhkb arrow keys
    leftbrace = "up"; # [
    apostrophe = "right"; # '
    slash = "down"; # /
    semicolon = "left"; # ;

    # Cut/Copy/Paste clipboard
    x = "S-delete";
    c = "C-insert";
    v = "S-insert";

    # Printscreen (screenshot)
    i = "sysrq";

    # Escape
    dot = "esc"; # .

    # Media keys
    a = "volumedown";
    s = "volumeup";
    d = "mute";
    # f = "micmute";
    space = "playpause";

    # Both volume keys together trigger media key
    "a+s" = "media";

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

    # Toggle capslock
    rightshift = "capslock";
  };

  # Shift+volume keys control tracks
  shift = {
    volumedown = "previoussong";
    volumeup = "nextsong";
    mute = "micmute";
  };
}
