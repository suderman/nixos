_: {
  # Hyprland on nvidia desktop
  wayland.windowManager.hyprland = {
    lua = {
      # Temporary workaround for hyprwm/hyprland-plugins#697 on NVIDIA.
      rounding = 0;
      monitors = [
        {
          output = "DP-1";
          mode = "3840x2160@160.00Hz";
          position = "0x440";
          scale = "1.33";
        }
        {
          # ASUS PB278, rotated 90 degrees to the right of DP-1
          output = "DP-3";
          mode = "2560x1440@59.95Hz";
          position = "2880x0";
          scale = "1";
          transform = 1;
        }
      ];
      env = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    };
    hyprbars = {
      enable = true;
      barBlur = false;
      barPrecedenceOverBorder = true;
    };
    waybar.codex-lb.enable = true;
    waybar.minimax-quota.enable = true;
    waybar.claude-quota.enable = true;
    waybar.herdr.enable = true;
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
