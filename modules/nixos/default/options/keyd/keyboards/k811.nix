# Logitech K811 Bluetooth Keyboard
# https://www.amazon.ca/product/dp/B0099SMFP2/
{
  ids = ["046d:b317"];
  settings = {
    main = {
      ## Modifiers before:
      # [Capslock]
      # [fn] [Control] [Alt] [Meta] [Space] [Meta] [Alt]

      ## Modifiers after:
      # [Control]
      # [fn] [Control] [Alt] [Super] [Space] [Super] [Alt]
      capslock = "overloadt2(control, escape, 200)";
      leftshift = "layer(shift)";
      leftcontrol = "layer(control)";
      leftalt = "overload(super, f14)";
      leftmeta = "overload(alt, f13)";

      # Allow right modifers to be unique keys
      rightmeta = "rightmeta";
      rightalt = "rightalt";
      rightshift = "rightshift";
    };
  };
}
