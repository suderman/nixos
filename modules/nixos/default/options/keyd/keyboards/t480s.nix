# Thinkpad T480s Laptop (interal keyboard)
{
  ids = ["0001:0001"];
  settings = {
    main = {
      ## Modifers before:
      # [Tab]
      # [Capslock]
      # [fn] [Control] [Meta] [Alt] [Space] [Alt] [PrtSc] [Control]

      ## Modifer after:
      # [fn/Tab]
      # [Control]
      # [fn] [Control] [Alt] [Super] [Space] [Super] [PrtSc] [Control]
      tab = "overloadt2(fn, tab, 200)";
      leftshift = "layer(shift)";
      capslock = "overloadt2(control, escape, 100)";
      leftcontrol = "layer(control)";
      leftmeta = "layer(alt)";
      leftalt = "layer(super)";

      # Allow right modifers to be unique keys
      rightalt = "rightmeta";
      rightcontrol = "rightalt";
      rightshift = "rightshift";
    };
  };
}
