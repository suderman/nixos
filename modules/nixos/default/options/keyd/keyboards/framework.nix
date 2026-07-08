# Framework Laptop (internal keyboard)
{
  ids = ["0001:0001"];
  settings = {
    main = {
      ## Modifiers before:
      # [Tab]
      # [Capslock]
      # [Control] [fn] [Meta] [Alt] [Space] [Alt] [Control]

      ## Modifers after:
      # [Nav/Tab]
      # [Control]
      # [Control] [fn] [Alt] [Super] [Space] [Super] [Alt]
      tab = "overloadt2(fn, tab, 200)";
      capslock = "overloadt2(control, escape, 100)";
      leftshift = "layer(shift)";
      # leftcontrol = "layer(control)";
      leftcontrol = "s"; # my s key is broken...
      leftmeta = "overload(alt, f13)";
      leftalt = "overload(super, f14)";

      # Allow right modifers to be unique keys
      rightalt = "rightmeta";
      rightcontrol = "rightalt";
      rightshift = "rightshift";
    };
  };
}
