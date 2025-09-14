# Logitech K811 Bluetooth Keyboard
# https://www.amazon.ca/product/dp/B0099SMFP2/
{
  ids = ["046d:b317"];
  settings =
    {
      main = {
        ## Modifiers before:
        # [Tab]
        # [Capslock]
        # [fn] [Control] [Alt] [Meta] [Space] [Meta] [Alt]

        ## Modifiers after:
        # [Nav/Tab]
        # [Control]
        # [fn] [Control] [Alt] [Super] [Space] [Super] [Alt]
        tab = "overloadt2(nav, tab, 200)";
        capslock = "layer(control)";
        leftcontrol = "layer(control)";
        leftalt = "layer(alt)";
        leftmeta = "layer(super)";
        rightmeta = "layer(super)";
        rightalt = "layer(alt)";

        # Both volume keys together trigger media key
        "volumedown+volumeup" = "media";
      };
    }
    // import ./all.nix;
}
