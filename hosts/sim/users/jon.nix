{
  flake,
  config,
  lib,
  ...
}: {
  imports = [
    flake.homeModules.default
    # flake.homeModules.gnome
    flake.homeModules.hyprland
  ];

  # File sync
  services.syncthing.enable = true;

  # Music daemon
  services.mpd.enable = true;

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
    "Downloads"
    "Personal"
    "Work"
  ];

  persist.storage.files = [
    ".zsh_history"
    ".bash_history"
  ];

  programs.zwift.enable = true;
  programs.firefox.enable = true;
}
