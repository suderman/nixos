{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktops.hyprland
  ];

  # Create home folders (persisted)
  xdg.userDirs = let
    home = config.home.homeDirectory;
  in {
    desktop = "${home}/Personal/Action"; # persist
    download = "${home}/Downloads"; # persist
    documents = "${home}/Personal/Documents"; # persist
    music = "${home}/Personal/Music"; # persist
    pictures = "${home}/Personal/Pictures"; # persist
    videos = "${home}/Personal/Movies"; # persist
  };

  persist.storage.directories = [
    ".ssh"
    "Downloads"
    "Personal"
    "Work"
  ];

  persist.storage.files = [
    ".zsh_history"
    ".bash_history"
  ];

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
  wayland.windowManager.hyprland.enablePlugins = false;

  programs.rofi = {
    extraSinks = ["bluez_output.AC_3E_B1_9F_43_35.1"]; # pixel buds pro
    hiddenSinks = ["alsa_output.pci-0000_01_00.1.hdmi-stereo"]; # monitor speakers
  };

  # Sync health data
  # services.withings-sync.enable = true;

  # Programs
  programs.zwift.enable = true;
  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    externalExtensions = {
      inherit
        (config.programs.chromium.registry)
        auto-tab-discard-suspend
        dark-reader
        fake-data
        floccus-bookmarks-sync
        i-still-dont-care-about-cookies
        one-password
        return-youtube-dislike
        sponsorblock
        ublock-origin
        ;
    };
  };
}
