{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Hyprland
  wayland.windowManager.hyprland.settings = {
    # 4k display
    monitor = ["DP-1, 3840x2160@160.00Hz, 0x0, 1.33"];

    # nvidia fixes
    env = [
      "LIBVA_DRIVER_NAME,nvidia"
      "XDG_SESSION_TYPE,wayland"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    ];

    # 0.42's explicit sync wasn't needed on my system and when it's enabled
    # Firefox and other apps freeze and crash
    render.explicit_sync = true;
  };

  # Set to false if plugins barf notification errors
  # wayland.windowManager.hyprland.enablePlugins = true;
  wayland.windowManager.hyprland.enablePlugins = false;

  programs.rofi = {
    extraSinks = ["bluez_output.AC_3E_B1_9F_43_35.1"]; # pixel buds pro
    hiddenSinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo"]; # monitor speakers
    # hiddenSinks = [ "alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink" ]; # optical now connected to desk speakers
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  home.packages = [
    # inputs.nvf.packages."${pkgs.stdenv.system}".nvf
    inputs.neovim.packages."${pkgs.stdenv.system}".default
  ];

  programs.chromium = {
    enable = true;

    externalExtensions = {
      inherit
        (config.programs.chromium.registry)
        auto-tab-discard-suspend
        # contextsearch
        dark-reader
        fake-data
        floccus-bookmarks-sync
        # global-speed
        i-still-dont-care-about-cookies
        one-password
        return-youtube-dislike
        sponsorblock
        ublock-origin
        ;
    };
  };
}
