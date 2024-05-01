{
  
  # Tapping both shift keys will activate capslock.
  shift = {
    leftshift = "capslock";
    rightshift = "capslock";
  };


  # Meta (Super) layer 
  meta = {

    # Open app switcher (command tab)
    tab = "swapm(switcher, M-tab)";

    # esc: Switch to next window in the application group
    # esc = "A-f6";

    # Cut/Copy/Paste clipboard
    x = "S-delete";
    c = "C-insert";
    v = "S-insert";

  };

  # Switcher (while holding down meta/super-tab)
  "switcher:M" = {

    # Meta-Backtick\Esc: Switch to previous application
    grave = "M-S-tab"; # `
    esc = "M-S-tab";

    # vi keys
    k = "M-up";
    l = "M-right";
    j = "M-down";
    h = "M-left";

  }; 

  # Nav (Vim & Emacs style navigation)
  nav = {

    # Open app switcher (command tab)
    tab = "swapm(switcher, M-tab)";

    # esc: Switch to next window in the application group
    esc = "A-f6";

    # vi keys
    k = "up";
    l = "right";
    j = "down";
    h = "left";
    u = "pageup";
    d = "pagedown";
    w = "C-right";
    b = "C-left";

    # emacs keys
    f = "right";
    q = "home"; # normally a
    e = "end";
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
    # d = "mute";

    # Simulate super with spacebar 
    space = "layer(meta)";

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

}
