# Logitech Gaming Mouse G600 Keyboard
# https://www.amazon.ca/gp/product/B0086UK7IQ/
{
  ids = [ "046d:c24a" ];
  settings = {
    main = {

      # G4 (nudge scroll wheel): super-right 
      f4 = "M-right";

      # G5 (nudge scroll wheel): super+left
      f5 = "M-left";

      # G6 (far-right mouse button): super
      f6 = "layer(super)";

      # G7 (middle raised): is super-rightclick
      f7 = "M-rightmouse";

      # G8 (middle sunken): super-leftclick
      f8 = "M-leftmouse";

      # Modifiers on mouse
      f9 = "layer(super)";
      f10 = "layer(alt)";
      f11 = "layer(shift)";

      # Media control 
      f15 = "volumeup";
      f16 = "playpause";
      f18 = "volumedown";
      f19 = "mute";

      # Print Screen (screenshot)
      f17 = "sysrq";

    };

  } // import ./all.nix;

}
