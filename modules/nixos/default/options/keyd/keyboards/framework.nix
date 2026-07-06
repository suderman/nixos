# Framework Laptop (internal keyboard)
{
  ids = ["0001:0001"];
  settings =
    {
      main =
        {
          ## Modifiers before:
          # [Tab]
          # [Capslock]
          # [Control] [fn] [Meta] [Alt] [Space] [Alt] [Control]

          ## Modifers after:
          # [Nav/Tab]
          # [Control]
          # [Control] [fn] [Alt] [Super] [Space] [Super] [Alt]
          tab = "overloadt2(nav, tab, 200)";
          capslock = "overload(control, escape)";
          leftshift = "layer(shift)";
          # leftcontrol = "layer(control)";
          leftcontrol = "s"; # my s key is broken...
          leftmeta = "layer(alt)";
          leftalt = "layer(super)";

          # Allow right modifers to be unique keys
          rightalt = "rightmeta";
          rightcontrol = "rightalt";
          rightshift = "rightshift";

          # Both volume keys together trigger media key
          "volumedown+volumeup" = "media";
        }
        // import ./home-row-mods.nix;
    }
    // import ./all.nix;
}
