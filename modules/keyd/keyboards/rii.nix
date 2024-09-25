{
  ids = [ "1997:2466" ];
  settings = {
    main = {

      # Use tab as custom modifier
      tab = "overloadt2(nav, tab, 200)";

      # Leave the default modifiers as-is
      leftshift = "layer(shift)";
      leftalt = "layer(alt)";
      leftmeta = "layer(super)";
      rightmeta = "layer(super)";
      rightalt = "layer(alt)";
      rightshift = "layer(shift)";

      # Alias compose to alt
      compose = "layer(alt)";

      # Alias homepage to super
      homepage = "layer(super)";

    };

  } // import ./all.nix;

}
