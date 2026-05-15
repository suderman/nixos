_: {
  # Hyprland embedded display (laptop)
  wayland.windowManager.hyprland = {
    lua = {
      enable = true;
      monitors = [
        {
          output = "eDP-1";
          mode = "2256x1504@59.9990001";
          position = "500x1440";
          scale = "1.333333";
        }
      ];
    };
    enablePlugins = false; # dynamic cursors crash on lua path for now
    enableOfficialPlugins = true;
  };

  # Record screen with CPU-based AV1 encoder
  programs.printscreen = {
    framerate = 20;
    codec = "libsvtav1";
    params = {
      preset = 5;
      crf = 45;
    };
  };
}
