# Logitech Gaming Mouse G600 Keyboard
{
  ids = [ "046d:c24a" ];
  settings = {
    main = {

      # Move workspaces to the right (nudge scroll wheel) 
      f4 = "M-A-right";

      # Move workspaces to the left (nudge scroll wheel)
      f5 = "M-A-left";

      # Far-right mouse button is command layer
      f6 = "layer(meta)";

      # Middle lower (G7) is meta-leftclick (move windows)
      f7 = "M-leftmouse";

      # Middle upper (G8) is meta-rightclick (resize windows)
      f8 = "M-rightmouse";

      # Modifiers on mouse
      f9 = "layer(meta)";
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
