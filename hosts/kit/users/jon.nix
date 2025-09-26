{flake, ...}: {
  imports = [
    flake.homeModules.default
    # flake.homeModules.users.jon
    # flake.homeModules.desktops.hyprland
  ];

  # Hyprland on nvidia desktop
  wayland.windowManager.hyprland = {
    settings = {
      # 4k display
      monitor = ["DP-1, 3840x2160@160.00Hz, 0x0, 1.33"];
      # nvidia fixes
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      ];
      render.explicit_sync = true;
    };
    enablePlugins = false; # set false if plugins barf errors
  };

  # Hide monitor speakers
  programs.rofi.hiddenSinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo"];

  # Programs
  programs.zwift.enable = true;
  programs.firefox.enable = true;
  programs.chromium.enable = true;

  # Wallet
  programs.sparrow.enable = true;

  # Gaming
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;

  # User services
  services.mpd.enable = true;
  services.syncthing.enable = true;
}
