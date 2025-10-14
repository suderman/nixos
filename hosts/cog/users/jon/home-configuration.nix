{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.users.jon
    flake.homeModules.desktops.hyprland
  ];

  # Hyprland embedded display (laptop)
  wayland.windowManager.hyprland = {
    settings.monitor = ["eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"];
    enablePlugins = true; # set false if plugins barf errors
  };

  # Override homm-assistant client with local instance
  programs.home-assistant.url = "https://hass.cog";

  # Override jellyfin client with local instance
  programs.jellyfin.url = "https://jellyfin.cog";

  # Program
  programs.sparrow.enable = true;

  # Gaming
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;
  programs.zwift.enable = true; # fitness

  # User services
  services.mpd.enable = true;
  services.syncthing.enable = true;

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
