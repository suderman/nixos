# Rii Bluetooth Keyboard with Touchpad
# https://www.amazon.ca/gp/product/B081CTNB5W/
{
  ids = ["1997:2466"];
  settings = {
    main = {
      # Use tab as custom modifier
      tab = "overloadt2(fn, tab, 200)";

      # Assign super to leftalt key
      leftalt = "overload(super, f14)";

      # Assign alt to compose key
      compose = "overload(alt, f13)";

      # Assign super to homepage key
      homepage = "overload(super, f14)";
    };
  };
}
