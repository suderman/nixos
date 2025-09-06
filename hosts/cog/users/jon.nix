{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.common
    flake.homeModules.extra
    flake.homeModules.hyprland
    flake.homeModules.jon
  ];

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
    "Code"
    "Downloads"
    "Personal"
    "Work"
  ];

  persist.storage.files = [
    ".zsh_history"
    ".bash_history"
    ".git-credentials"
  ];

  # Hyprland enabled in configuration.nix
  wayland.windowManager.hyprland.settings = {
    monitor = [
      # embedded display (laptop)
      "eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"
    ];
  };

  # Set to false if plugins barf notification errors
  # wayland.windowManager.hyprland.enablePlugins = false;
  wayland.windowManager.hyprland.enablePlugins = true;

  programs.rofi = {
    extraSinks = ["bluez_output.AC_3E_B1_9F_43_35.1"]; # pixel buds pro
    hiddenSinks = [];
  };
}
