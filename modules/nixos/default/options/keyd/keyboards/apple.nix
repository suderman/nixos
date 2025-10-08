# Apple Wired Keyboard with Numpad
# https://www.amazon.ca/gp/product/B07K7V1FWC/
{
  ids = ["05ac:0220" "05ac:024f"];
  settings =
    {
      main = {
        ## Modifers before:
        # [Tab]
        # [Capslock]
        # [Control] [Alt] [Meta] [Space] [Meta] [Alt]

        ## Modifers after:
        # [Nav/Tab]
        # [Control]
        # [Control] [Alt] [Super] [Space] [Super] [Alt]
        tab = "overloadt2(nav, tab, 200)";
        capslock = "layer(control)";
        leftshift = "layer(shift)";
        leftcontrol = "layer(control)";
        leftalt = "layer(alt)";
        leftmeta = "layer(super)";

        # Allow right modifers to be unique keys
        rightmeta = "rightmeta";
        rightalt = "rightalt";
        rightshift = "rightshift";

        # Both volume keys together trigger media key
        "volumedown+volumeup" = "media";
      };
    }
    // import ./all.nix;
}
