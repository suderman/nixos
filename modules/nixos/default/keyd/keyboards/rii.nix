# Rii Bluetooth Keyboard with Touchpad
# https://www.amazon.ca/gp/product/B081CTNB5W/
{
  ids = ["1997:2466"];
  settings =
    {
      main = {
        # Use tab as custom modifier
        tab = "overloadt2(nav, tab, 200)";

        # Assign super to leftalt key
        leftalt = "layer(super)";

        # Assign alt to compose key
        compose = "layer(alt)";

        # Assign super to homepage key
        homepage = "layer(super)";
      };
    }
    // import ./all.nix;
}
