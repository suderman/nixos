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
      # [Control] [Alt] [Super] [Space] [Super] [Alt]
      tab = "overloadt2(nav, tab, 200)";
      capslock = "layer(control)";
      leftcontrol = "layer(control)";
      leftalt = "layer(alt)";
      leftmeta = "layer(super)";
      rightmeta = "layer(super)";
      rightalt = "layer(alt)";

    };

  } // import ./all.nix;

}
