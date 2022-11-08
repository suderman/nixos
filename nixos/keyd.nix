{ pkgs, ... }:
{

  # Install keyd package
  environment.systemPackages = [ pkgs.keyd ];

  # Create keyd group
  users.groups.keyd.name = "keyd";

  # Create systemd service
  systemd.services.keyd = {
    description = "key remapping daemon";
    requires = [ "local-fs.target" ];
    after = [ "local-fs.target" ];
    wantedBy = [ "sysinit.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.keyd}/bin/keyd";
      # Restart = "on-failure";
    };
  };

  # Add quirks to make touchpad's "disable-while-typing" work properly
  environment.etc."libinput/local-overrides.quirks".text = ''
    [keyd]
    MatchUdevType=keyboard
    MatchVendor=0xFAC
    AttrKeyboardIntegration=internal
  '';

  # Configuration for keyd
  environment.etc."keyd/default.conf".text = ''
    [ids]

    # Framework Laptop
    # AT Translated Set 2 keyboard
    0001:0001

    # Tapping both shift keys will activate capslock.
    [shift]

    leftshift = capslock
    rightshift = capslock


    # While holding down command/super-tab
    [app:M]

    # Meta-Tab: Switch to next application
    tab = M-tab
    right = M-tab

    # Meta-Backtick: Switch to previous application
    ` = M-S-tab
    left = M-S-tab


    # Vim-like mode for navigation
    [nav]

    # vi keys
    k = up
    l = right
    j = down
    h = left
    u = pageup
    d = pagedown
    w = C-right
    b = C-left

    # emacs keys
    f = right
    a = home
    e = end
    p = pageup
    n = pagedown

    # hhkb keys
    [ = up
    ' = right
    / = down
    ; = left

    # Cut/Copy/Paste clipboard
    x = S-delete
    c = C-insert
    v = S-insert

    # escape
    . = esc

    # New command layer, inherit from meta
    [meta_cmd:M]

    # tap space to switch to nav
    space = swap(nav)

    # Open app switcher (command tab)
    tab = swap2(app, M-tab)

    # backtick: Switch to next window in the application group
    ` = A-f6

    # escape
    . = esc

    # Cut/Copy/Paste clipboard
    x = S-delete
    c = C-insert
    v = S-insert

    # Select tabs in many programs
    1 = A-1
    2 = A-2
    3 = A-3
    4 = A-4
    5 = A-5
    6 = A-6
    7 = A-7
    8 = A-8
    9 = A-9


    # New command layer, inherit from ctrl
    [control_cmd:C]

    # tap space to switch to nav
    space = swap(nav)

    # Open app switcher (command tab)
    tab = swap2(app, M-tab)

    # backtick: Switch to next window in the application group
    ` = A-f6

    # escape
    . = esc

    # Cut/Copy/Paste clipboard
    x = S-delete
    c = C-insert
    v = S-insert

    # Select tabs in many programs
    1 = A-1
    2 = A-2
    3 = A-3
    4 = A-4
    5 = A-5
    6 = A-6
    7 = A-7
    8 = A-8
    9 = A-9


    # Default mapping
    [main]

    ## before:  
    # [Capslock]
    # [Control] [fn] [Meta] [Alt] [Space] [Alt] [Control]
    ## after:  
    # [Control/Esc]
    # [Meta] [fn] [Alt] [Control/Meta] [Space] [Meta] [Alt]
    capslock = overload(control, esc)
    leftcontrol = layer(meta)
    leftmeta = layer(alt)
    leftalt = overload(control_cmd, macro(leftmeta))
    rightalt = layer(meta)
    f12 = toggle(main_meta)


    # Alternative to default mapping
    [main_meta]

    ## before:  
    # [Capslock]
    # [Control] [fn] [Meta] [Alt] [Space] [Alt] [Control]
    ## after: 
    # [Control/Esc]
    # [Meta] [fn] [Alt] [Meta] [Space] [Meta] [Alt]
    leftalt = layer(meta_cmd)
    f12 = toggle(main)
  '';

}
