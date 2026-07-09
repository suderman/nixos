# Thinkpad T480s Laptop (interal keyboard)
{
  ids = ["0001:0001"];
  settings = {
    main = {
      ## Modifers before:
      # [Capslock]
      # [fn] [Control] [Meta] [Alt] [Space] [Alt] [PrtSc] [Control]

      ## Modifer after:
      # [Control]
      # [fn] [Control] [Alt] [Super] [Space] [Super] [PrtSc] [Control]
      leftshift = "layer(shift)";
      capslock = "overloadt2(control, escape, 200)";
      leftcontrol = "layer(control)";
      leftmeta = "overload(alt, f13)";
      leftalt = "overload(super, f14)";

      # Allow right modifers to be unique keys
      rightalt = "rightmeta";
      rightcontrol = "rightalt";
      rightshift = "rightshift";
    };
  };
}
