_: {
  # Hyprland on nvidia desktop
  wayland.windowManager.hyprland = {
    lua = {
      enable = true;
      monitors = [
        {
          output = "DP-1";
          mode = "3840x2160@160.00Hz";
          position = "0x0";
          scale = "1.33";
        }
      ];
      env = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };
    enablePlugins = false; # dynamic cursors crash on lua path for now
    enableOfficialPlugins = true;
  };

  # Hide monitor speakers
  sound.hiddenSinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo"];

  # Record screen with nvidia's AV1 encoder
  programs.printscreen = {
    codec = "av1_nvenc";
    framerate = 20;
    params = {
      preset = 8;
      cq = 32;
      rc = "vbr";
    };
  };
}
