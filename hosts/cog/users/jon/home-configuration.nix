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

  # User services
  services.mpd.enable = true;
  services.syncthing.enable = true;
  services.garmin = {
    enable = true;
    deviceId = "091e_4cda_0000cb7d522d";
    dataDir = "${config.home.storageDirectory}/fenix";
  };
}
