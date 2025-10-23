# wallpaper
{
  config,
  pkgs,
  ...
}: {
  # Enable wallpaper service
  services.swww.enable = true;

  # Persist last wallpaper path
  persist.storage.directories = [".cache/swww"];

  # Set a wallpaper (random if none specified)
  home.packages = let
    inherit (config.home) homeDirectory;
    inherit (config.xdg.userDirs) extraConfig;
    dir = "${extraConfig.XDG_PICTURES_DIR or "${homeDirectory}/Pictures"}/Wallpapers";
  in [
    (pkgs.self.mkScript {
      name = "wallpaper";
      text = toString [
        "swww img"
        "--transition-type=any"
        "--transition-duration=1"
        "\${1:-\$(find ${dir} -type f | shuf -n 1)}"
      ];
    })
  ];

  wayland.windowManager.hyprland.settings = {
    # Keybind to change it up
    bind = ["super+alt, p, exec, wallpaper"];
    # Pretty animations in hyprland
    animations.layerrule = ["animation fade, swww-daemon"];
  };

  # Select specific wallpaper in Yazi
  programs.yazi.settings.opener.wallpaper = [
    {
      run = ''wallpaper "$@"'';
      desc = "Set wallpaper";
      block = false;
      orphan = true;
      for = "unix";
    }
  ];
}
