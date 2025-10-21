{lib, ...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 5;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = lib.mkForce [
        {
          path = "screenshot";
          blur_size = 4;
          blur_passes = 3;
          noise = 0.0117;
          contrast = 1.3000;
          brightness = 0.8000;
          vibrancy = 0.2100;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = lib.mkForce [
        {
          monitor = "";
          size = "250, 50";
          outline_thickness = 3;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.64; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          fade_on_empty = true;
          placeholder_text = "  Enter Password 󰈷 ";
          hide_input = false;
          position = "0, 80";
          halign = "center";
          valign = "bottom";
        }
      ];

      label = lib.mkForce [
        # Current time
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<b><big> $(date +"%H:%M:%S") </big></b>"'';
          font_size = 100;
          position = "0, 160";
          halign = "center";
          valign = "center";

          # User label
        }
        {
          monitor = "";
          text = ''Hey <span text_transform="capitalize" size="larger">$USER</span>'';
          font_size = 20;
          position = "0, 0";
          halign = "center";
          valign = "center";

          # Type to unlock
        }
        {
          monitor = "";
          text = "Type to unlock!";
          font_size = 16;
          position = "0, 30";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };
}
