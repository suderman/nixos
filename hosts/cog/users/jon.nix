{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktops.hyprland
    flake.homeModules.users.jon
  ];

  # embedded display (laptop)
  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"
  ];
  # Set to false if plugins barf notification errors
  wayland.windowManager.hyprland.enablePlugins = false;

  programs.home-assistant = {
    enable = true;
    url = "https://hass.cog";
  };

  programs.jellyfin = {
    enable = true;
    url = "https://jellyfin.cog";
  };
  programs.sparrow.enable = true;
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;
}
