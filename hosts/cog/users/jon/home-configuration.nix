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
    lua = {
      enable = true;
      monitors = [
        {
          output = "eDP-1";
          mode = "2256x1504@59.9990001";
          position = "500x1440";
          scale = "1.333333";
        }
      ];
    };
    enablePlugins = false; # dynamic cursors crash on lua path for now
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

  services.hermes-agent = {
    enable = true;
    agents = {
      june.client = "kit";
      pax.client = "kit";
      cid.client = "kit";
      dot.client = "gem";
    };
  };

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
