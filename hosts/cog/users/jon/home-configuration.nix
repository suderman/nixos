{
  config,
  lib,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];

  # Hyprland embedded display (laptop)
  wayland.windowManager.hyprland = {
    settings.monitor = ["eDP-1, 2256x1504@59.9990001, 500x1440, 1.333333"];
    enablePlugins = true; # dynamic cursors work on v0.55.0
    enableOfficialPlugins = false; # hyprbars/hyprexpo broken on v0.55.0
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

  # easy remote access to june from here too
  programs.zsh.initContent =
    lib.mkAfter
    # sh
    ''
      june() {
        ssh -t kit june "$@"
      }
    '';

  # Record screen with CPU-based AV1 encoder
  programs.printscreen = {
    framerate = 20;
    codec = "libsvtav1";
    params = {
      preset = 5;
      crf = 45;
    };
  };

  # Email, calendars, contacts
  accounts.enable = true;
}
