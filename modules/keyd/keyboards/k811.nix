# Logitech K811
{
  ids = [ "046d:b317" ];
  settings = {
    main = {

      ## Modifiers before:  
      # [Tab]
      # [Capslock]
      # [fn] [Control] [Alt] [Meta] [Space] [Meta] [Alt] 

      ## Modifiers after:  
      # [Nav/Tab]
      # [Control]
      # [fn] [Control] [Alt] [Meta] [Space] [Meta] [Alt]
      tab = "overload(nav, tab)";
      capslock = "layer(control)";
      leftcontrol = "layer(control)";
      leftalt = "layer(alt)";
      leftmeta = "layer(meta)";
      rightmeta = "layer(meta)";
      rightalt = "layer(alt)";

    };

  } // import ./all.nix;

}
