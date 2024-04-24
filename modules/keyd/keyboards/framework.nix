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
      # [Control] [fn] [Alt] [Meta] [Space] [Meta] [Alt]
      tab = "overload(nav, tab)";
      capslock = "layer(control)";
      leftcontrol = "layer(control)";
      leftmeta = "layer(alt)";
      leftalt = "layer(meta)";
      rightalt = "layer(meta)";
      rightmeta = "layer(alt)";

    };

  } // import ./all.nix;

}
