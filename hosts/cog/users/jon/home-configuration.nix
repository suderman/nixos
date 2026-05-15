{flake, ...}: {
  imports =
    [
      flake.homeModules.default
      flake.homeModules.desktop.hyprland
      flake.homeModules.users.jon
    ]
    ++ flake.lib.ls ./.;

  # Override homm-assistant client with local instance
  programs.home-assistant.url = "https://hass.cog";

  # Override jellyfin client with local instance
  programs.jellyfin.url = "https://jellyfin.cog";

  # Program
  programs.sparrow.enable = true;

  # Gaming
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;
  programs.citron.enable = true;
  programs.zwift.enable = true; # fitness
  programs.opencode.enable = true;
  programs.mmx-cli.enable = true;

  # User services
  services.syncthing.enable = true;

  # Music
  services.mpd.enable = true;
  programs.ncmpcpp.enable = true; # old client
  programs.rmpc.enable = true; # new client
  programs.projectm.enable = true; # visualizer

  # Email, calendars, contacts
  accounts.enable = true;
}
