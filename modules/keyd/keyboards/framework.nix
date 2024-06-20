# Framework Laptop
{
  ids = [ "0001:0001" ];
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
      tab = "overloadt2(nav, tab, 200)";
      capslock = "layer(control)";
      leftcontrol = "layer(control)";
      leftmeta = "layer(alt)";
      leftalt = "layer(super)";
      rightalt = "layer(super)";
      rightcontrol = "layer(alt)";

      # Both volume keys together trigger media key
      "volumedown+volumeup" = "media";

    };

  } // import ./all.nix;

}
