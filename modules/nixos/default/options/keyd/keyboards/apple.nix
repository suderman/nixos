# Apple Wired Keyboard with Numpad
# https://www.amazon.ca/gp/product/B07K7V1FWC/
{
  ids = ["05ac:0220" "05ac:024f"];
  settings = {
    main = {
      ## Modifers before:
      # [Capslock]
      # [Control] [Alt] [Meta] [Space] [Meta] [Alt]

      ## Modifers after:
      # [Control]
      # [Control] [Alt] [Super] [Space] [Super] [Alt]
      capslock = "overloadt2(control, escape, 200)";
      leftshift = "layer(shift)";
      leftcontrol = "layer(control)";
      leftalt = "overload(alt, f13)";
      leftmeta = "overload(super, f14)";

      # Allow right modifers to be unique keys
      rightmeta = "rightmeta";
      rightalt = "rightalt";
      rightshift = "rightshift";
    };
  };
}
