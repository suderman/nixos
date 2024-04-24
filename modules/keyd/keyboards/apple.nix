# Apple Keyboard
{
  ids = [ "05ac:0220" "05ac:024f" ];
  settings = {
    main = {

      ## Modifers before:  
      # [Tab]
      # [Capslock]
      # [Control] [Alt] [Meta] [Space] [Meta] [Alt] 

      ## Modifers after:  
      # [Nav/Tab]
      # [Control]
      # [Control] [Alt] [Meta] [Space] [Meta] [Alt]
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
