# wallpaper
{pkgs, ...}: {
  services.swww = {
    enable = true;
    package = pkgs.swww;
  };

  # Persist last wallpaper path
  persist.storage.directories = [".cache/swww"];

  wayland.windowManager.hyprland.settings.bind = [];

  programs.yazi.settings.opener.wallpaper = [
    {
      run = ''swww img --transition-type=any --transition-duration=1 "$@"'';
      desc = "Set wallpaper";
      block = false;
      orphan = true;
      for = "unix";
    }
  ];
}
