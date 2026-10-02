# Framework Laptop (internal keyboard)
{
  ids = ["0001:0001"];
  settings.main = {
    ## Modifiers before:
    # [Capslock]
    # [Control] [fn] [Meta] [Alt] [Space] [Alt] [Control]

    ## Modifiers after:
    # [Control/Escape]
    # [Control+Alt+Shift] [fn] [Alt] [Super] [Space] [Super] [Alt]
    capslock = "overloadt2(control, escape, 200)";
    leftshift = "layer(shift)";
    leftcontrol = "layer(controlaltshift)"; # Moonlight shortcut modifiers
    leftmeta = "overload(alt, f13)";
    leftalt = "overload(super, f14)";

    # Allow right modifiers to be unique keys
    rightalt = "rightmeta";
    rightcontrol = "rightalt";
    rightshift = "rightshift";
  };
}
